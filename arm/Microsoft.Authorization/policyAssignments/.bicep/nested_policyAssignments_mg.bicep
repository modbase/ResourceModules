targetScope = 'managementGroup'

@sys.description('Required. Specifies the name of the policy assignment.')
@maxLength(24)
param name string

@sys.description('Optional. This message will be part of response in case of policy violation.')
param description string = ''

@sys.description('Optional. The display name of the policy assignment.')
param displayName string = ''

@sys.description('Required. Specifies the ID of the policy definition or policy set definition being assigned.')
param policyDefinitionId string

@sys.description('Optional. Parameters for the policy assignment if needed.')
param parameters object = {}

@sys.description('Optional. The managed identity associated with the policy assignment. Policy assignments must include a resource identity when assigning \'Modify\' policy definitions.')
@allowed([
  'SystemAssigned'
  'None'
])
param identity string = 'SystemAssigned'

@sys.description('Required. The IDs Of the Azure Role Definition list that is used to assign permissions to the identity. You need to provide either the fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles for the list IDs for built-in Roles. They must match on what is on the policy definition')
param roleDefinitionIds array = []

@sys.description('Optional. The policy assignment metadata. Metadata is an open ended object and is typically a collection of key-value pairs.')
param metadata object = {}

@sys.description('Optional. The messages that describe why a resource is non-compliant with the policy.')
param nonComplianceMessage string = ''

@sys.description('Optional. The policy assignment enforcement mode. Possible values are Default and DoNotEnforce. - Default or DoNotEnforce')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@sys.description('Required. The Target Scope for the Policy. The name of the management group for the policy assignment')
param managementGroupId string

@sys.description('Optional. The policy excluded scopes')
param notScopes array = []

@sys.description('Optional. Location for all resources.')
param location string = deployment().location

var nonComplianceMessage_var = {
  message: !empty(nonComplianceMessage) ? nonComplianceMessage : null
}

var identity_var = identity == 'SystemAssigned' ? {
  type: identity
} : null

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: name
  location: location
  properties: {
    displayName: !empty(displayName) ? displayName : null
    metadata: !empty(metadata) ? metadata : null
    description: !empty(description) ? description : null
    policyDefinitionId: policyDefinitionId
    parameters: parameters
    nonComplianceMessages: !empty(nonComplianceMessage) ? array(nonComplianceMessage_var) : []
    enforcementMode: enforcementMode
    notScopes: !empty(notScopes) ? notScopes : []
  }
  identity: identity_var
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = [for roleDefinitionId in roleDefinitionIds: if (!empty(roleDefinitionIds) && identity != 'None') {
  name: guid(managementGroupId, roleDefinitionId, location, name)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: policyAssignment.identity.principalId
  }
}]

@sys.description('Policy Assignment Name')
output name string = policyAssignment.name

@sys.description('Policy Assignment principal ID')
output principalId string = identity == 'SystemAssigned' ? policyAssignment.identity.principalId : ''

@sys.description('Policy Assignment resource ID')
output resourceId string = extensionResourceId(tenantResourceId('Microsoft.Management/managementGroups', managementGroupId), 'Microsoft.Authorization/policyAssignments', policyAssignment.name)
