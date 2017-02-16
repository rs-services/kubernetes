name 'Kubernetes Cluster'
rs_ca_ver 20161221
short_description "![logo](https://dl.dropboxusercontent.com/u/2202802/nav_logo.png)

Creates a Kubernetes cluster"

long_description "### Description

#### Kubernetes

Kubernetes is an open source cluster manager, a software package that manages a cluster of servers as a scalable pool of resources for deploying Docker containers.

#### This CloudApp

RightScale's Self-Service integration for Kubernetes makes it easy to launch and scale a dynamically-sized cluster, manage access, and deploy workloads across the pool of servers.

---

### Parameters

#### Master Count

Choose the number of masters for the cluster.

#### Minimum Node Count

Enter the minimum number of nodes for the cluster. Autoscaling will maintain node count between minimum and maximum.

#### Maximum Node Count

Enter the maximum number of nodes for the cluster. Autoscaling will maintain node count between minimum and maximum.

#### Cloud

Choose a target cloud for this cluster.

#### Admin IP

Enter your public IP address as visible to the public Internet. This will be used to create a rule in the cluster's security group to allow you full access to the cluster for administration. You can visit [http://ip4.me](http://ip4.me) to verify your public IP.

---

### Outputs

#### Launch Kubernetes dashboard

Click this link to launch the Kubernetes dashboard.

#### SSH to master server

This output displays SSH login information in the form ssh://*username*@*ip_address*. Use your usual SSH connection method to initiate a SSH session on the master server.

#### Authorized admin IPs

Contains a list of IP addresses that have been authorized for full administrative access to the cluster.

---

### Actions

#### Add Admin IP

This action can be used to authorize an additional IP for full administrative access to the cluster.

#### Update Autoscaling Range

This action will modify the minimum and maximum number of cluster nodes. Although the action completes right away, please wait up to 30 minutes for the requested changes to happen in the background, especially when new servers are being launched.

---"

permission "read_credentials" do
  actions   "rs_cm.index", "rs_cm.show", "rs_cm.index_sensitive", "rs_cm.show_sensitive"
  resources "rs_cm.credentials"
end

mapping "map_cloud" do {
  "AWS" => {
    "cloud" => "EC2 us-east-1",
    "datacenter" => "us-east-1e",
    "account_id" => "816783988377",
    "instance_type" => "m3.large" },
  "VMware" => {
    "cloud" => "",
    "datacenter" => "",
    "account_id" => null,
    "instance_type" => "" } }
end

# parameter "master_count" do
#   type "number"
#   label "Master Count"
#   category "Application"
#   description "Number of cluster masters."
#   allowed_values 1, 3, 5
#   default 1
# end

parameter "node_count_min" do
  type "number"
  label "Minimum Node Count"
  category "Application"
  description "Minimum number of cluster nodes."
  min_value 1
  max_value 19
  default 3
end

parameter "node_count_max" do
  type "number"
  label "Maximum Node Count"
  category "Application"
  description "Maximum number of cluster nodes."
  min_value 1
  max_value 19
  default 6
end

parameter "cloud" do
  type "string"
  label "Cloud"
  category "Application"
  description "Target cloud for this cluster."
  allowed_values "AWS"#, "VMware"
  default "AWS"
end

parameter "admin_ip" do
  type "string"
  label "Admin IP"
  category "Application"
  description "Allowed source IP for cluster administration. This IP address will have full access to the cluster."
  allowed_pattern "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"
  constraint_description "Please enter a single IP address. Additional IPs can be added after launch."
end

resource 'cluster_sg', type: 'security_group' do
  name join(['cluster_sg_', last(split(@@deployment.href, '/'))])
  cloud map($map_cloud, $cloud, "cloud")
end

resource 'cluster_sg_rule_int_tcp', type: 'security_group_rule' do
  protocol 'tcp'
  direction 'ingress'
  source_type 'group'
  security_group @cluster_sg
  group_owner map($map_cloud, $cloud, "account_id")
  protocol_details do {
    'start_port' => '0',
    'end_port' => '65535'
  } end
end

resource 'cluster_sg_rule_int_udp', type: 'security_group_rule' do
  protocol 'udp'
  direction 'ingress'
  source_type 'group'
  security_group @cluster_sg
  group_owner map($map_cloud, $cloud, "account_id")
  protocol_details do {
    'start_port' => '0',
    'end_port' => '65535'
  } end
end

resource 'cluster_sg_rule_admin', type: 'security_group_rule' do
  protocol 'tcp'
  direction 'ingress'
  source_type 'cidr_ips'
  security_group @cluster_sg
  cidr_ips join([$admin_ip, '/32'])
  protocol_details do {
    'start_port' => '0',
    'end_port' => '65535'
  } end
end

resource 'cluster_master', type: 'server_array' do
  name 'cluster-master'
  cloud map($map_cloud, $cloud, "cloud")
  datacenter map($map_cloud, $cloud, "datacenter")
  instance_type map($map_cloud, $cloud, "instance_type")
  server_template find('Kubernetes', revision: 0)
  inputs do {
    'RS_CLUSTER_ROLE' => 'text:master'
  } end
  state 'disabled'
  array_type 'alert'
  elasticity_params do {
    'bounds' => {
      'min_count'            => 1,
      'max_count'            => 1
    },
    'pacing' => {
      'resize_calm_time'     => 30,
      'resize_down_by'       => 1,
      'resize_up_by'         => 1
    },
    'alert_specific_params' => {
      'decision_threshold'   => 0,
      'voters_tag_predicate' => 'cluster_master'
    }
  } end
end

resource 'cluster_node', type: 'server_array' do
  name 'cluster-node'
  cloud map($map_cloud, $cloud, "cloud")
  datacenter map($map_cloud, $cloud, "datacenter")
  instance_type map($map_cloud, $cloud, "instance_type")
  server_template find('Kubernetes', revision: 0)
  inputs do {
    'RS_CLUSTER_ROLE' => 'text:node'
  } end
  state 'disabled'
  array_type 'alert'
  elasticity_params do {
    'bounds' => {
      'min_count'            => $node_count_min,
      'max_count'            => $node_count_max
    },
    'pacing' => {
      'resize_calm_time'     => 30,
      'resize_down_by'       => 1,
      'resize_up_by'         => 3
    },
    'alert_specific_params' => {
      'decision_threshold'   => 1,
      'voters_tag_predicate' => 'cluster_node'
    }
  } end
end

output "ssh_url" do
  label "SSH to master server"
  category "Kubernetes"
end

output "dashboard_url" do
  label "Launch Kubernetes dashboard"
  category "Kubernetes"
end

output "admin_ips" do
  label "Authorized admin IPs"
  category "Kubernetes"
end

operation 'launch' do
  description 'Launch the application'
  definition 'launch'
  output_mappings do {
    $ssh_url => join(["ssh://rightscale@", $master_ip]),
    $admin_ips => $new_admin_ips,
    $dashboard_url => join(["https://", $master_ip, ".nip.io:8443/console"])
  } end
end

operation 'enable' do
  description 'Enable the application'
  definition 'enable'
end

operation 'terminate' do
  description 'Terminate the application'
  definition 'terminate'
end

operation 'op_add_admin_ip' do
  label 'Add Admin IP'
  description 'Authorize an additional admin IP for full access to the cluster'
  definition 'add_admin_ip'
  output_mappings do {
    $admin_ips => $new_admin_ips
  } end
end

operation 'op_update_autoscaling_range' do
  label 'Update Autoscaling Range'
  description 'Modify the minimum and maximum number of cluster nodes'
  definition 'resize_cluster'
end

define launch(@cluster_master, @cluster_node, @cluster_sg, @cluster_sg_rule_admin, @cluster_sg_rule_int_tcp, @cluster_sg_rule_int_udp, $admin_ip, $cloud) return @cluster_master, @cluster_node, @cluster_sg, @cluster_sg_rule_admin, @cluster_sg_rule_int_tcp, @cluster_sg_rule_int_udp, $master_ip, $new_admin_ips do

  call sys_get_execution_id() retrieve $execution_id

  @@deployment.multi_update_inputs(inputs: {
    'RS_CLUSTER_NAME':'text:' + $execution_id,
    'RS_CLUSTER_CLOUD':'text:' + $cloud,
    'RS_CLUSTER_TYPE':'text:kubernetes'
  })

  if $cloud == "AWS"
    provision(@cluster_sg)

    call security_group_name($cloud, @cluster_sg) retrieve $security_group_name
    call update_field(@cluster_sg_rule_int_tcp, "group_name", $security_group_name) retrieve @cluster_sg_rule_int_tcp
    call update_field(@cluster_sg_rule_int_udp, "group_name", $security_group_name) retrieve @cluster_sg_rule_int_udp

    provision(@cluster_sg_rule_int_tcp)
    provision(@cluster_sg_rule_int_udp)
    provision(@cluster_sg_rule_admin)

    call update_field(@cluster_master, "security_group_hrefs", [@cluster_sg]) retrieve @cluster_master
    call update_field(@cluster_node, "security_group_hrefs", [@cluster_sg]) retrieve @cluster_node

    call update_field(@cluster_master, "cloud_specific_attributes", {"root_volume_size" => 100, "root_volume_type_uid" => "gp2"}) retrieve @cluster_master
    call update_field(@cluster_node, "cloud_specific_attributes", {"root_volume_size" => 100, "root_volume_type_uid" => "gp2"}) retrieve @cluster_node
  end

  concurrent return @cluster_master, @cluster_node do
    provision(@cluster_master)
    provision(@cluster_node)
  end

  $new_admin_ips = $admin_ip

  if $cloud == "AWS"
    $master_ip = @cluster_master.current_instances().public_ip_addresses[0]
  else
    $master_ip = @cluster_master.current_instances().private_ip_addresses[0]
  end
end

define enable(@cluster_master, @cluster_node) return @cluster_master, @cluster_node do
  
  call sys_get_execution_id() retrieve $execution_id

  # run install script on master
  call run_executable(first(@cluster_master.current_instances()), {rightscript: {name: "Kubernetes Master"}, inputs: {
    'RS_CLUSTER_NAME': 'text:' + $execution_id
  }})
  
  # run install script on nodes
  call run_executable(@cluster_node.current_instances(), {rightscript: {name: "Kubernetes Node"}, inputs: {
    'RS_CLUSTER_NAME': 'text:' + $execution_id,
    'KUBE_CLUSTER_JOIN_CMD': 'text:' + cred('KUBE_' + $execution_id + '_CLUSTER_TOKEN')
  }})
end

define terminate(@cluster_master, @cluster_node) return @cluster_master, @cluster_node do
  # remove servers first to ensure auto_terminate can cleanly remove security groups
  concurrent do
    delete(@cluster_master)
    delete(@cluster_node)
  end
end

define resize_cluster(@cluster_node, $node_count_min, $node_count_max) return @cluster_node, $node_count_min, $node_count_max do
  @cluster_node.update(server_array: {
    "elasticity_params": {
      "bounds": {
        "min_count": $node_count_min,
        "max_count": $node_count_max
      }
    }
  })
end

define add_admin_ip(@cluster_sg, $admin_ip) return $new_admin_ips do
  @new_rule = {
    "namespace": "rs",
    "type": "security_group_rule",
    "fields": {
      "protocol": "tcp",
      "direction": "ingress",
      "source_type": "cidr_ips",
      "security_group_href": @cluster_sg,
      "cidr_ips": join([$admin_ip, '/32']),
      "protocol_details": {
        "start_port": "0",
        "end_port": "65535"
      }
    }
  }

  provision(@new_rule)

  $sg_cidr_ips = @cluster_sg.security_group_rules().cidr_ips[]

  $sg_ips = map $sg_cidr_ip in $sg_cidr_ips return $sg_ip do
    if $sg_cidr_ip
      $sg_ip = first(split($sg_cidr_ip, "/"))
    else
      $sg_ip = null
    end
  end

  $new_admin_ips = join($sg_ips, ", ")
end

define security_group_name($cloud, @group) return $name do
  if $cloud == "Google"
    $name = @group.resource_uid
  else
    $name = @group.name
  end
end

define update_field(@declaration, $field_name, $field_value) return @declaration do
  $json = to_object(@declaration)
  $json["fields"][$field_name] = $field_value
  @declaration = $json
end

define reboot_array_servers(@array) do
  $wake_condition = "/^(operational|stranded|stranded in booting|stopped|terminated|inactive|error)$/"
  $rebooting_condition = "/^(decommissioning|pending|booting)$/"
  @current_instances = @array.current_instances()
  $array_name = @array.name

  @array.update(server_array: {
    "state": "disabled"
  })

  @current_instances.reboot()
  sleep_until any?(@current_instances.state[], $rebooting_condition)
  sleep_until all?(@current_instances.state[], $wake_condition)
  $operational = all?(@current_instances.state[], "operational")

  if !$operational
    raise "One or more servers failed to reboot. Check array " + $array_name + "."
  end

  @array.update(server_array: {
    "state": "enabled"
  })
end

# Returns all tags for a specified resource. Assumes that only one resource
# is passed in, and will return tags for only the first resource in the collection.
#
# @param @resource [ResourceCollection] a ResourceCollection containing only a
#   single resource for which to return tags
#
# @return $tags [Array<String>] an array of tags assigned to @resource
define get_tags_for_resource(@resource) return $tags do
  $tags = []
  $tags_response = rs_cm.tags.by_resource(resource_hrefs: [@resource.href])
  $inner_tags_ary = first(first($tags_response))["tags"]
  $tags = map $current_tag in $inner_tags_ary return $tag do
    $tag = $current_tag["name"]
  end
  $tags = $tags
end

# Fetches the execution id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The execution ID of the current cloud app
define sys_get_execution_id() return $execution_id do
  call get_tags_for_resource(@@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $tag_value = last($tag_split_by_value_delimiter)
    $value_split_by_slashes = split($tag_value, "/")
    $execution_id = last($value_split_by_slashes)
  else
    $execution_id = "N/A"
  end
end

# Return a rightscript href (or null) if it was found in the runnable bindings
# of the supplied ServerTemlate
#
# @param @server_template [ServerTemplateResourceCollection] a collection
#   containing exactly one ServerTemplate to search for the specified RightScript
# @param $name [String] the string name of the RightScript to return
# @param $options [Hash] a hash of options where the possible keys are;
#   * runlist [String] one of (boot|operational|decommission).  When supplied
#     the search will be restricted to the supplied runlist, otherwise all
#     runnable bindings will be evaulated, and the first result will be returned
#
# @return $href [String] the href of the first RightScript found (or null)
#
# @raise a string error message if the @server_template parameter contains more
#   than one (1) ServerTemplate
define server_template_get_rightscript_from_runnable_bindings(@server_template, $name, $options) return $href do
  if size(@server_template) != 1
    raise "server_template_get_rightscript_from_runnable_bindings() expects exactly one ServerTemplate in the @server_template parameter.  Got "+size(@server_template)
  end
  $href = null
  $select_hash = {"right_script": {"name": $name}}
  if contains?(keys($options),["runlist"])
    $select_hash["sequence"] = $options["runlist"]
  end
  @right_scripts = select(@server_template.runnable_bindings(), $select_hash)
  if size(@right_scripts) > 0
    $href = @right_scripts.right_script().href
  end
end

# Does some validation and gets the server template for an instance
#
# @param @instance [InstanceResourceCollection] the instance for which to get
#   the server template
#
# @return [ServerTemplateReourceCollection] The server template for the @instance
#
# @raise a string error message if the @instance parameter is not an instance
#   collection
# @raise a string error message if the @instance does not have a server_template
#   rel
define instance_get_server_template(@instance) return @server_template do
  $type = to_s(@instance)
  if !($type =~ "instance")
    raise "instance_get_server_template requires @instance to be of type rs_cm.instances.  Got "+$type+" instead"
  end
  $stref = select(@instance.links, {"rel": "server_template"})
  if size($stref) == 0
    raise "instance_get_server_template can't get the ServerTemplate of an instance which does not have a server_template rel."
  end
  @server_template = @instance.server_template()
end

# Run a rightscript or recipe on a server or instance collection.
#
# @param @target [ServerResourceCollection|InstanceResourceCollection] the
#   resource collection to run the executable on.
# @param $options [Hash] a hash of options where the possible keys are;
#   * ignore_lock [Bool] whether to run the executable even when the instance
#     is locked.  Default: false
#   * wait_for_completion [Bool] Whether this definition should block waiting for
#     the executable to finish running or fail.  Default: true
#   * inputs [Hash] the inputs to pass to the run_executable request.  Default: {}
#   * rightscript [Hash] a hash of rightscript details where the possible keys are;
#     * name [String] the name of the rightscript to execute
#     * revision [Int] the revision number of the rightscript to run.
#       If not supplied the "latest" (which could be HEAD) will be used.
#     * href [String] if specified href takes prescedence and defines the *exact*
#       rightscript and revision to execute
#     * revmatch [String] a ServerTemplate runlist name (one of "boot",
#       "operational","decomission").  When supplied only the "name" option
#       is considered and is required.  The RightScript which is executed will
#       be the one with the same name that is in the specified runlist.
#   * recipe [String] the recipe name to execute (must be associated with the
#     @target's ServerTemplate)
#
# @return @task [TaskResourceCollection] the task returned by the run_executable
#   request
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceInstances.html#multi_run_executable
# @see http://reference.rightscale.com/api1.5/resources/ResourceTasks.html
define run_executable(@target,$options) return @tasks do
  @tasks = rs_cm.tasks.empty()
  $default_options = {
    ignore_lock: false,
    wait_for_completion: true,
    inputs: {}
  }

  $merged_options = $options + $default_options

  @instances = rs_cm.instances.empty()
  $target_type = type(@target)
  if $target_type == "rs_cm.servers"
    @instances = @target.current_instance()
  elsif $target_type == "rs_cm.instances"
    @instances = @target
  else
    raise "run_executable() can not operate on a collection of type "+$target_type
  end

  $run_executable_params_hash = {inputs: $merged_options["inputs"]}
  if contains?(keys($merged_options),["rightscript"])
    if contains?(keys($merged_options["rightscript"]),["revmatch"])
      if !contains?(keys($merged_options["rightscript"]),["name"])
        raise "run_executable() requires both 'name' and 'revmatch' when specifying 'revmatch'"
      end
      call instance_get_server_template(@instances) retrieve @server_template
      call server_template_get_rightscript_from_runnable_bindings(@server_template, $merged_options["rightscript"]["name"], {runlist: $merged_options["rightscript"]["revmatch"]}) retrieve $script_href
      if !$script_href
        raise "run_executable() unable to find RightScript named "+$merged_options["rightscript"]["name"]+" in the "+$merged_options["rightscript"]["revmatch"]+" runlist of the ServerTempate "+@server_template.name
      end
      $run_executable_params_hash["right_script_href"] = $script_href
    elsif any?(keys($merged_options["rightscript"]),"/(name|href)/")
      if contains?(keys($merged_options["rightscript"]),["href"])
        $run_executable_params_hash["right_script_href"] = $merged_options["rightscript"]["href"]
      else
        @scripts = rs_cm.right_scripts.get(filter: ["name=="+$merged_options["rightscript"]["name"]])
        if empty?(@scripts)
          raise "run_executable() unable to find RightScript with the name "+$merged_options["rightscript"]["name"]
        end
        $revision = 0
        if contains?(keys($merged_options["rightscript"]),["revision"])
          $revision = $merged_options["rightscript"]["revision"]
        end
        $revisions, @script_to_run = concurrent map @script in @scripts return $available_revision,@script_with_revision do
          $available_revision = @script.revision
          if $available_revision == $revision
            @script_with_revision = @script
          else
            # TODO: This won't be necessary when RCL assigns the proper empty return
            # collection type.
            @script_with_revision = rs_cm.right_scripts.empty()
          end
        end
        if empty?(@script_to_run)
          raise "run_executable() found the script named "+$merged_options["rightscript"]["name"]+" but revision "+$revision+" was not found.  Available revisions are "+to_s($revisions)
        end
        $run_executable_params_hash["right_script_href"] = @script_to_run.href
      end
    else
      raise "run_executable() requires either 'name' or 'href' when executing a RightScript.  Found neither."
    end
  elsif contains?(keys($merged_options),["recipe"])
    $run_executable_params_hash["recipe_name"] = $merged_options["recipe"]
  else
    raise "run_executable() requires either 'rightscript' or 'recipe' in the $options.  Found neither."
  end

  @tasks = @instances.run_executable($run_executable_params_hash)

  if $merged_options["wait_for_completion"]
    sleep_until(all?(@tasks.summary[], "/^(completed|failed|aborted)/i"))
    if any?(@tasks.summary[], "/failed|aborted/i")
      raise "Failed to run " + to_s($run_executable_params_hash)
    end
  end
end
