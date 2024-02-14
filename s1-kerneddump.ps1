function Get-HelperComObject {
    $code = @"
         using System;
         using System.Runtime.InteropServices;
         public class ImpTest
         {
             [DllImport("Ole32.dll", CharSet = CharSet.Auto)]
             public static extern int CoSetProxyBlanket(
                IntPtr pProxy,
                uint dwAuthnSvc,
                uint dwAuthzSvc,
                uint pServerPrincName,
                uint dwAuthLevel,
                uint dwImpLevel,
                IntPtr pAuthInfo,
                uint dwCapabilities
             );
             public static int SetSecurity(object objDCOM)
             {
                 IntPtr dispatchInterface = Marshal.GetIDispatchForObject(objDCOM);
                 int hr = CoSetProxyBlanket(
                    dispatchInterface,
                    0xffffffff,
                    0xffffffff,
                    0xffffffff,
                    0, // Authentication Level
                    3, // Impersonation Level
                    IntPtr.Zero,
                    64
                 );
                 return hr;
             }
         }
"@
    try {
        Add-Type -TypeDefinition $code | Out-Null

        log "Initializing SentinelHelper COM object..." | Out-Null
        $SentinelHelper = New-Object -com "SentinelHelper.1"

        log "SentinelHelper COM object initialized successfully" | Out-Null
        [ImpTest]::SetSecurity($SentinelHelper)  | Out-Null
        $SentinelHelper

    } catch {
        log -Msg "Error getting helper com object" -Ex $_ | Out-Null
    }
}

function DoLiveKernelDump {
    param(
        [string] $outPath
    )
    try {
        log "Trying to dump kernel to '$outPath'"
        $SentinelHelper = Get-HelperComObject
        $SentinelHelper.LiveKernelDump($outPath)
	log "Done!"
    } catch {
        log -Msg "Error running command: " -Ex $_
    }
}

function log {
    param(
        [string] $Msg,
        [string] $Ex
    )
    Write-Host "[$(Get-Date)] $Msg $Ex"
}

DoLiveKernelDump -outPath "C:\kernel.dmp"
