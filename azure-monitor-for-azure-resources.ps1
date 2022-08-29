
$subscription_id = "aaaaaaaa-bbbb-bbbbb-bbbb-ccccccc"
$resource_group_name = "resource-group-name"
$action_group_name = "action-group-name"

# Connecting to Azure
$automation_account = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $automation_account.TenantID -ApplicationId $automation_account.ApplicationID -CertificateThumbprint $automation_account.CertificateThumbprint


# Defining Metric Rules for Storage Account
# Transaction = Number of requests to storage account (successful + failed)
$storage_account_transactions = New-AzMetricAlertRuleV2Criteria -MetricName "Transactions" -TimeAggregation Total -Operator GreaterThan -Threshold 300 
# Amount of storage used by storage account over specific period
$storage_account_used_capacity = New-AzMetricAlertRuleV2Criteria -MetricName "UsedCapacity" -TimeAggregation Average -Operator GreaterThan -Threshold 1Gb 
$storage_account_availability = New-AzMetricAlertRuleV2Criteria -MetricName "Availability" -TimeAggregation Average -Operator LessThan -Threshold 0.9 
$storage_account_egress =  New-AzMetricAlertRuleV2Criteria -MetricName "Egress" -TimeAggregation Total -Operator GreaterThan -Threshold 1Gb
$storage_account_ingress =  New-AzMetricAlertRuleV2Criteria -MetricName "Ingress" -TimeAggregation Total -Operator GreaterThan -Threshold 1Gb


$action_group_id = New-AzActionGroup -ActionGroupId "/subscriptions/$subscription_id/resourcegroups/$resource_group_name/providers/Microsoft.Insights/actiongroups/$action_group_name"
$resources_list = Get-AzResource -ResourceGroupName $resource_group_name | Select ResourceName, ResourceType 
	$resource_name = ""
	 ForEach ($resource in $resources_list)
    	{ 
				if ($resource.ResourceType -like "*Microsoft.Storage/storageAccounts*")
				{
					# Minimum TimeSpan for Used Capacity is 1 Hour
					$resource_name = $resource.ResourceName
					Add-AzMetricAlertRuleV2 -Name "Total Transactions of $resource_name " -ResourceGroupName $resource_group_name -WindowSize 00:05:00 -Frequency 00:05:00 -TargetResourceScope "/subscriptions/$subscription_id/resourceGroups/$resource_group_name/providers/Microsoft.Storage/storageAccounts/$resource_name" -TargetResourceType "Microsoft.Storage/storageAccounts" -TargetResourceRegion "Canada Central" -Description "Storage account alert for Total Trasactions" -Severity 3 -ActionGroup $action_group_id -Condition $storage_account_transactions
					Add-AzMetricAlertRuleV2 -Name "Used capacity of storage $resource_name " -ResourceGroupName $resource_group_name -window_size 00:60:00 -Frequency 00:05:00 -TargetResourceScope "/subscriptions/$subscription_id/resourceGroups/$resource_group_name/providers/Microsoft.Storage/storageAccounts/$resource_name" -TargetResourceType "Microsoft.Storage/storageAccounts" -TargetResourceRegion "Canada Central" -Description "Used capacity of storage" -Severity 0 -ActionGroup $action_group_id -Condition $storage_account_used_capacity
					Add-AzMetricAlertRuleV2 -Name "Availability of $resource_name " -ResourceGroupName $resource_group_name -WindowSize 00:05:00 -Frequency 00:05:00 -TargetResourceScope "/subscriptions/$subscription_id/resourceGroups/$resource_group_name/providers/Microsoft.Storage/storageAccounts/$resource_name" -TargetResourceType "Microsoft.Storage/storageAccounts" -TargetResourceRegion "Canada Central" -Description "Storage account alert for Availability" -Severity 3 -ActionGroup $action_group_id -Condition $storage_account_availability
					Add-AzMetricAlertRuleV2 -Name "Storage $resource_name  Egress  " -ResourceGroupName $resource_group_name -WindowSize 00:05:00 -Frequency 00:05:00 -TargetResourceScope "/subscriptions/$subscription_id/resourceGroups/$resource_group_name/providers/Microsoft.Storage/storageAccounts/$resource_name" -TargetResourceType "Microsoft.Storage/storageAccounts" -TargetResourceRegion "Canada Central" -Description "Egress alert" -Severity 3 -ActionGroup $action_group_id -Condition $storage_account_egress
					Add-AzMetricAlertRuleV2 -Name "Storage $resource_name  Ingress" -ResourceGroupName $resource_group_name -WindowSize 00:05:00 -Frequency 00:05:00 -TargetResourceScope "/subscriptions/$subscription_id/resourceGroups/$resource_group_name/providers/Microsoft.Storage/storageAccounts/$resource_name" -TargetResourceType "Microsoft.Storage/storageAccounts" -TargetResourceRegion "Canada Central" -Description "Ingress alert" -Severity 3 -ActionGroup $action_group_id -Condition $storage_account_ingress
					Write-Output "Alert Rules created for Storage account"
				}
		}
