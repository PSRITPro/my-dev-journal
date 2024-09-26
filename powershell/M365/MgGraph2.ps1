
$cId="2f6dde73-eb69-4089-bc4e-6ef06b828c0e"
$tId = "c518f592-d3fe-405a-b17d-456bcf93a271"

$ClientSecretCredential = Get-Credential -Credential $cId
# Enter client_secret in the password prompt.
Connect-MgGraph -TenantId $tId -ClientSecretCredential $ClientSecretCredential

Connect-MgGraph -ClientId $cId -TenantId $tId

Get-MgSite

Connect-MgGraph -Identity