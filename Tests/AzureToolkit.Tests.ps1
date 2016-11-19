Import-Module $PSScriptRoot\..\AzureToolkit -Force

Describe "Get-AzureRmStorageContextFromAccountName" {
    Context "Null parameter provided" {
        It "fails" {
            { Get-AzureRmStorageContextFromAccountName -StorageAccountName $null } | Should Throw
        }
    }

    Context "Empty parameter provided" {
        It "fails" {
            { Get-AzureRmStorageContextFromAccountName -StorageAccountName "" } | Should Throw
        }
    }
}