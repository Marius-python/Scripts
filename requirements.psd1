# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'. 
    # To use the Az module in your function app, please uncomment the line below.
    #'Az' = '7.*'
    'Az.Accounts' = '2.*'
    'Az.Resources' = '1.*'
    'Az.Storage' = '4.*'
    'Microsoft.Graph.Users' = '1.*'
    'Microsoft.Graph.Authentication' = '1.*'
    'Microsoft.Graph.DirectoryObjects' = '1.*'
    'MSAL.PS' = '4.*'
}