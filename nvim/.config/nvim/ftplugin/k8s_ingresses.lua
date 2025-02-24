local commands = require 'kubectl.actions.commands'
local ingress_view = require 'kubectl.views.ingresses'
local mappings = require 'kubectl.mappings'

local cluster_to_profile = {
  ['spot-prod'] = 'default',
  ['spot-prod-bi-billing'] = 'default',
  ['spot-dev-us-east-2'] = 'dev',
}

local profile_to_onelogin = {
  default = 'https://spotinst.onelogin.com/client/apps/select/889121819',
  dev = 'https://spotinst.onelogin.com/client/apps/select/889121822',
}

vim.schedule(function()
  vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>(kubectl.ingress_aws)', '', {
    noremap = true,
    silent = true,
    desc = 'Open AWS Console for the ingress ALB',
    callback = function()
      local name, ns = ingress_view.getCurrentSelection()
      vim.notify('checking DNS of ingress ' .. name)
      commands.shell_command_async('kubectl', {
        'get',
        'ingress',
        name,
        '-n',
        ns,
        '-o',
        "jsonpath='{.status.loadBalancer.ingress[*].hostname}'",
      }, function(ingress_dns)
        -- remove surrounding quotes from ingress_dns
        ingress_dns = string.sub(ingress_dns, 2, -2)
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
    end,
  })
end)

vim.schedule(function()
  mappings.map_if_plug_not_set('n', 'gi', '<Plug>(kubectl.ingress_aws)')
end)
