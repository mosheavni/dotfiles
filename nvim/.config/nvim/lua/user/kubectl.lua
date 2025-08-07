local commands = require 'kubectl.actions.commands'
local M = {
  ingresses = {},
  ['applications.argoproj.io'] = {},
  ['certificaterequests.cert-manager.io'] = {},
  ['certificates.cert-manager.io'] = {},
  ['clusterissuers.cert-manager.io'] = {},
  ['clustersecretstores.external-secrets.io'] = {},
  ['externalsecrets.external-secrets.io'] = {},
  ['scaledobjects.keda.sh'] = {},
  ['targetgroupbindings.elbv2.k8s.aws'] = {},
  ['prometheuses.monitoring.coreos.com'] = {},
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

local get_profile_and_region = function()
  local cluster_name = require('kubectl.state').context['current-context']
  local aws_profile = os.getenv 'AWS_PROFILE' or cluster_to_profile[cluster_name]
  local region = os.getenv 'AWS_REGION'
    or vim.trim(vim.system({ 'aws', 'configure', 'get', 'region', '--profile', aws_profile }, { text = true }):wait().stdout)
  return aws_profile, region
end

local prompt_onelogin = function(aws_profile, cb)
  local onelogin_url = profile_to_onelogin[aws_profile]
  if not onelogin_url then
    vim.notify('No OneLogin URL configured for AWS_PROFILE: ' .. aws_profile, vim.log.levels.ERROR)
    return
  end
  vim.schedule(function()
    vim.ui.select({ 'Yes', 'No' }, { title = 'Open OneLogin before?' }, function(choice)
      if not choice then
        return
      end
      if choice == 'No' then
        cb()
        return
      end
      vim.ui.open(profile_to_onelogin[aws_profile])
      vim.defer_fn(function()
        cb()
      end, 3000)
    end)
  end)
end

-- open ALB on AWS console
M.ingresses.select = function(name, ns)
  local gvk = require('kubectl.resources.ingresses').definition.gvk
  commands.run_async('get_single_async', {
    gvk = gvk,
    namespace = ns,
    name = name,
    output = 'Json',
  }, function(data_raw)
    if not data_raw or data_raw == '' or data_raw == nil then
      return
    end
    local data = vim.json.decode(data_raw)
    local ingress_dns = vim.inspect(data.status.loadBalancer.ingress[1].hostname)
    vim.schedule(function()
      local aws_profile, region = get_profile_and_region()
      vim.notify('AWS_PROFILE: ' .. aws_profile .. ' AWS_REGION: ' .. region .. ' Ingress DNS: ' .. ingress_dns)
      local aws_cmd = {
        'aws',
        'elbv2',
        'describe-load-balancers',
        '--query',
        string.format('LoadBalancers[?DNSName==`%s`]', ingress_dns),
        '--profile',
        aws_profile,
        '--output',
        'json',
      }
      vim.system(aws_cmd, { text = true }, function(aws_output)
        local ok
        ok, aws_output = pcall(vim.json.decode, aws_output.stdout)
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
        prompt_onelogin(aws_profile, function()
          vim.ui.open(lb_url)
        end)
      end)
    end)
  end)
end

-- view Secret of the ServiceAccount
M.serviceaccounts.select = function(name, ns)
  local gvk = require('kubectl.resources.serviceaccounts').definition.gvk
  local client = require 'kubectl.client'
  local sa = client.get_single(vim.json.encode { gvk = gvk, namespace = ns, name = name, output = 'Json' })

  local sa_decoded = vim.json.decode(sa)
  local secret_name = sa_decoded.secrets and sa_decoded.secrets[1] and sa_decoded.secrets[1].name
  if secret_name then
    require('kubectl.state').filter_key = 'metadata.name=' .. secret_name .. ',metadata.namespace=' .. ns
    require('kubectl.state').filter = ''
    require('kubectl.resources.secrets').View()
  end
end

-- open ArgoCD application in browser
M['applications.argoproj.io'].select = function(name, ns)
  if not (name and ns) then
    vim.notify('ArgoCD application name and namespace are required', vim.log.levels.ERROR)
    return
  end
  local ingress_host = vim
    .system({ 'kubectl', 'get', 'ingress', '-n', ns, '-l', 'app.kubernetes.io/component=server', '-o', 'jsonpath={.items[].spec.rules[].host}' }, { text = true })
    :wait().stdout
  local final_host = string.format('https://%s/applications/argocd/%s', ingress_host, name)
  vim.notify('Opening ' .. final_host)
  vim.ui.open(final_host)
end

-- view ExternalSecrets of the ClusterSecretStore
M['clustersecretstores.external-secrets.io'].select = function(name)
  require('kubectl.state').filter_key = 'spec.secretStoreRef.name=' .. name .. ',spec.secretStoreRef.kind=ClusterSecretStore'
  require('kubectl.state').filter = ''
  require('kubectl.resources.fallback').View(nil, 'externalsecrets.external-secrets.io')
end

-- view Secret of ExternalSecret
M['externalsecrets.external-secrets.io'].select = function(name, ns)
  local gvk = require('kubectl.resources.fallback').definition.gvk
  local client = require 'kubectl.client'
  local es = client.get_single(vim.json.encode { gvk = gvk, namespace = ns, name = name, output = 'Json' })
  local es_decoded = vim.json.decode(es)
  local secret_name = es_decoded.status and es_decoded.status.binding and es_decoded.status.binding.name
  if secret_name then
    require('kubectl.state').filter_key = 'metadata.name=' .. secret_name .. ',metadata.namespace=' .. ns
    require('kubectl.state').filter = ''
    require('kubectl.resources.secrets').View()
  end
end

-- view CertificateRequests of the Certificate
M['certificates.cert-manager.io'].select = function(name, ns)
  require('kubectl.state').filter_key = 'metadata.ownerReferences.name=' .. name .. ',metadata.ownerReferences.kind=Certificate,metadata.namespace=' .. ns
  require('kubectl.state').filter = ''
  require('kubectl.resources.fallback').View(nil, 'certificaterequests.cert-manager.io')
end

M['scaledobjects.keda.sh'].select = function(name, ns)
  local gvk = require('kubectl.resources.fallback').definition.gvk
  local client = require 'kubectl.client'
  local so = client.get_single(vim.json.encode { gvk = gvk, namespace = ns, name = name, output = 'Json' })
  local so_decoded = vim.json.decode(so)
  local metric_names = so_decoded.status.externalMetricNames or {}
  for _, metric_name in ipairs(metric_names) do
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
end

M['targetgroupbindings.elbv2.k8s.aws'].select = function(name, ns)
  local gvk = require('kubectl.resources.fallback').definition.gvk
  local client = require 'kubectl.client'
  local tgb = client.get_single(vim.json.encode { gvk = gvk, namespace = ns, name = name, output = 'Json' })
  local tgb_decoded = vim.json.decode(tgb)
  local target_group_arn = tgb_decoded.spec.targetGroupARN
  if not target_group_arn then
    vim.notify('TargetGroupARN not found for TargetGroupBinding: ' .. name, vim.log.levels.ERROR)
    return
  end
  local aws_profile, region = get_profile_and_region()
  local tg_url = string.format('https://%s.console.aws.amazon.com/ec2/home?region=%s#TargetGroup:targetGroupArn=%s', region, region, target_group_arn)
  prompt_onelogin(aws_profile, function()
    vim.ui.open(tg_url)
  end)
end

M['prometheuses.monitoring.coreos.com'].select = function(name, ns)
  local gvk = require('kubectl.resources.fallback').definition.gvk
  local client = require 'kubectl.client'
  local prometheus = client.get_single(vim.json.encode { gvk = gvk, namespace = ns, name = name, output = 'Json' })
  local prometheus_decoded = vim.json.decode(prometheus)
  local pod_selector = prometheus_decoded.status and prometheus_decoded.status.selector
  local res = {}
  for _, lbl in ipairs(vim.split(pod_selector, ',')) do
    table.insert(res, 'metadata.labels.' .. lbl)
  end
  require('kubectl.state').filter_key = table.concat(res, ',')
  require('kubectl.state').filter = ''
  require('kubectl.resources.pods').View()
end

return M
