local commands = require 'kubectl.actions.commands'
local M = {
  ingresses = {},
  ['applications.argoproj.io'] = {},
  ['clustersecretstores.external-secrets.io'] = {},
  ['certificates.cert-manager.io'] = {},
  ['scaledobjects.keda.sh'] = {},
  serviceaccounts = {},
}

local cluster_to_profile = {
  ['spot-prod'] = 'default',
  ['spot-prod-bi-billing'] = 'default',
  ['spot-dev-us-east-2'] = 'dev',
}

local profile_to_onelogin = {
  default = 'https://spotinst.onelogin.com/client/apps/select/889121819',
  dev = 'https://spotinst.onelogin.com/client/apps/select/889121822',
}

M.ingresses.select = function(name, ns)
  commands.run_async('get_single_async', {
    kind = 'Ingress',
    namespace = ns,
    name = name,
    output = 'Json',
  }, function(data_raw)
    local data = vim.json.decode(data_raw)
    local ingress_dns = vim.inspect(data.status.loadBalancer.ingress[1].hostname)
    vim.schedule(function()
      local cluster_name = require('kubectl.state').context['current-context']
      local aws_profile = os.getenv 'AWS_PROFILE' or cluster_to_profile[cluster_name]
      local region = os.getenv 'AWS_REGION' or vim.trim(commands.shell_command('aws', { 'configure', 'get', 'region', '--profile', aws_profile }))
      vim.notify(ingress_dns)
      vim.notify('AWS_PROFILE: ' .. aws_profile .. ' AWS_REGION: ' .. region)
      local aws_cmd = {
        'elbv2',
        'describe-load-balancers',
        '--query',
        string.format('LoadBalancers[?DNSName==`%s`]', ingress_dns),
        '--profile',
        aws_profile,
        '--output',
        'json',
      }
      commands.shell_command_async('aws', aws_cmd, function(aws_output)
        local ok
        ok, aws_output = pcall(vim.json.decode, aws_output)
        if not ok then
          vim.notify('Failed to parse AWS output\n' .. aws_output)
          return
        end
        if vim.tbl_count(aws_output) == 0 then
          vim.notify('ALB not found for DNS ' .. ingress_dns)
          return
        end
        local alb_arn = aws_output and aws_output[1].LoadBalancerArn
        local lb_url =
          string.format('https://%s.console.aws.amazon.com/ec2/home?region=%s#LoadBalancer:loadBalancerArn=%s;tab=listenersb', region, region, alb_arn)
        vim.schedule(function()
          vim.ui.select({ 'Yes', 'No' }, { title = 'Open OneLogin before?' }, function(choice)
            if not choice then
              return
            end
            if choice == 'No' then
              vim.ui.open(lb_url)
              return
            end
            vim.ui.open(profile_to_onelogin[aws_profile])
            vim.defer_fn(function()
              vim.ui.open(lb_url)
            end, 3000)
          end)
        end)
      end)
    end)
  end)
end

M.serviceaccounts.select = function(name, ns)
  local client = require 'kubectl.client'
  local sa = client.get_single(vim.json.encode { kind = 'ServiceAccount', namespace = ns, name = name, output = 'Json' })

  local sa_decoded = vim.json.decode(sa)
  local secret_name = sa_decoded.secrets and sa_decoded.secrets[1] and sa_decoded.secrets[1].name
  if secret_name then
    require('kubectl.state').filter_key = 'metadata.name=' .. secret_name .. ',metadata.namespace=' .. ns
    require('kubectl.resources.secrets').View()
  end
end

M['applications.argoproj.io'].select = function(name, ns)
  local ingress_host =
    commands.shell_command('kubectl', { 'get', 'ingress', '-n', ns, '-l', 'app.kubernetes.io/component=server', '-o', 'jsonpath={.items[].spec.rules[].host}' })
  local final_host = string.format('https://%s/applications/argocd/%s', ingress_host, name)
  vim.notify('Opening ' .. final_host)
  vim.ui.open(final_host)
end

M['clustersecretstores.external-secrets.io'].select = function(name)
  require('kubectl.state').filter_key = 'spec.secretStoreRef.name=' .. name .. ',spec.secretStoreRef.kind=ClusterSecretStore'
  require('kubectl.resources.fallback').View(nil, 'externalsecrets.external-secrets.io')
end

M['certificates.cert-manager.io'].select = function(name, ns)
  require('kubectl.state').filter_key = 'metadata.ownerReferences.name=' .. name .. ',metadata.ownerReferences.kind=Certificate,metadata.namespace=' .. ns
  require('kubectl.resources.fallback').View(nil, 'certificaterequests.cert-manager.io')
end

M['scaledobjects.keda.sh'].select = function(name, ns)
  local client = require 'kubectl.client'
  local so = client.get_single(vim.json.encode { kind = 'ScaledObject', namespace = ns, name = name, output = 'Json' })
  local so_decoded = vim.json.decode(so)
  local metric_name = so_decoded.status.externalMetricNames[1]
  vim.system({
    'kubectl',
    'get',
    '--raw',
    string.format('/apis/external.metrics.k8s.io/v1beta1/namespaces/%s/%s?labelSelector=scaledobject.keda.sh%%2Fname%%3D%s', ns, metric_name, name),
  }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.notify('Failed to get external metric: ' .. result.stderr, vim.log.levels.ERROR)
      return
    end
    local metrics = vim.json.decode(result.stdout)
    if not metrics or not metrics.items or #metrics.items == 0 then
      vim.notify('No metrics found for ScaledObject: ' .. name, vim.log.levels.WARN)
      return
    end
    local metric_value = metrics.items[1].value
    local num_value = metric_value
    --remove the 'm' suffix from the metric value
    if metric_value:sub(-1) == 'm' then
      num_value = metric_value:sub(1, -2)
    end
    local real_metric = tonumber(num_value) / 1000 -- Convert from milliseconds to seconds
    vim.notify(string.format('Current metric value for %s (%s): %d real metric (%s)', name, metric_name, real_metric, metric_value))
  end)
end

return M
