param resourceLocation string = resourceGroup().location
param loadBalancerFrontendVnet string
param loadBalancerFrontendVnetRG string
param loadBalancerFrontendSubnet string
param loadBalancerBasicBlock object = {
  loadbalancername: {
    sku: {
      name: 'Basic'
      tier: 'Regional'
    }
  }
}
param frontEndConfig array = [ // can be list of front end ip configuration objects
  {
    name: ''                      // string. Name of the front end
    privateIPAllocationMethod: '' // string. Should be either Static or Dynamic
    privateIPAddress: ''          // string. Keep it '' (i.e. empty) if the privateIPAllocation is Dynamic
  }
]

param backendAddressPools array = [ // Can be list of backend address pool objects
  {
    name: ''                  // string (name of the backned address pool)
  }
]
param lbProbes array = [ // can be list of load balancer probe objects
  {
    name: ''                  // string. Name of the health probe used by the frontend
    protocol: ''              // string. Should be either 
    port: ''                  // int
    intervalInSeconds: ''     // int
    numberOfProbes: ''        // int
  }
]

param lbRules array = [ // can be list of load balancing rule objects
  {
    name: ''                   // string
    frontendConfigId: ''       // string. Resource ID of the front end Ip config of the load balancer
    backendAddressPoolId: ''   // string. Resource ID of the backend Address Pool to which the load balancing rule will be associated
    protocol: ''               // string
    frontendPort: ''           // int
    backendPort: ''            // int
    enableFloatingIP: ''       // bool
    idleTimeOutinMinutes: ''   // int
    healthProbeId: ''          // string. Resource ID of the health probe used for the load balancing rule
  }
]
var loadbalancerBasicValues = items(loadBalancerBasicBlock)

resource loadbalancerSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${loadBalancerFrontendVnet}/${loadBalancerFrontendSubnet}'
  scope: resourceGroup(loadBalancerFrontendVnetRG)
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2021-05-01' = [for lb in loadbalancerBasicValues: {
  name: lb.key
  location: resourceLocation
  sku: {
    name: lb.value.sku.name
    tier: lb.value.sku.tier
  }
  properties: {
    frontendIPConfigurations: [ for fconfig in frontEndConfig : {
      name: fconfig.name
      properties: {
        privateIPAllocationMethod: fconfig.privateIPAllocationMethod
        privateIPAddress: ((fconfig.privateIPAllocation == 'Static') && !empty(fconfig.privateIPAddress)) ? fconfig.privateIPAddress  : string('null')
        subnet: {
          id: loadbalancerSubnet.id
        }
      }
    }]
    backendAddressPools: [ for pool in backendAddressPools : {
      name: pool.name
    }]
    probes: [ for probe in lbProbes : {
      name: probe.name
      properties: {
        protocol: probe.protocol
        port: probe.port
      }
    }]
    loadBalancingRules: [ for rule in lbRules: {
      name: rule.name
      properties: {
        frontendIPConfiguration: {
          id: rule.frontendConfigId
        }
        backendAddressPool: {
          id: rule.backendAddressPoolId
        }
        protocol: 'Tcp'
        frontendPort: rule.frontendPort
        backendPort: rule.backendPort
        enableFloatingIP: rule.enableFloatingIP
        idleTimeoutInMinutes: rule.idleTimeoutInMinutes
        probe: {
          id: rule.healhProbeId
        }
      }
    }]
  }
}]
