Class App.Installer Extends %RegisteredObject
{

Parameter Namespace = "MYAPP";

Parameter SourcePath = "/app/src";

XData Install [ XMLNamespace = INSTALLER ]
{
<Manifest> 
    <Namespace Name="${Namespace}" Create="yes" Ensemble="">
        <Import File="${SourcePath}" Recurse="1" Flags="cuk" />
        <Production Name="App.Prod" AutoStart="1"/>
        <!-- dummy GCP credentials -->
        <Invoke Class="%SYSTEM.OBJ" Method="Load" CheckStatus="true">
            <Arg Value="/app/data/config-cred.xml"/>
        </Invoke>
    </Namespace>
    <Namespace Name="%SYS" Create="no">
        <!-- basic SSL config -->
        <Invoke Class="Security.SSLConfigs" Method="Import" CheckStatus="true">
            <Arg Value="/app/data/config-ssl.xml"/>
        </Invoke>
    </Namespace>
</Manifest>
}

/// This is a method generator whose code is generated by XGL. 
/// Main setup method
ClassMethod RunManifest(ByRef pVars, pLogLevel As %Integer = 0, pInstaller As %Installer.Installer) As %Status [ CodeMode = objectgenerator, Internal ]
{
    Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Install")
}

/// Entry point    
ClassMethod Run(ByRef vars) As %Status
{
    try { 
        write "START INSTALLER",! 
        
        // set default values for installer variables
        for ivar="SourcePath","Namespace" {
            if '$data(vars(ivar)) set vars(ivar)=$parameter($classname(), ivar)
        } 
        
        set sc = ..RunManifest(.vars) 
        if sc {
            write !,"INSTALLER SUCCESS",!
        } else {
            do $SYSTEM.Process.Terminate($JOB,1)
        }

        // endpoint for translation-demo branch
        $$$ThrowOnError(..CreateWebApp(..#Namespace, "/myapp/api/translation", "App.API.ShowTranslation.disp"))

        set ns = $NAMESPACE
        zn "MYAPP"
        Try {
            Do ##class(dc.myapp.util.MLInstaller).Exec()
            Do ##class(dc.myapp.util.NotebookExamplesInstaller).Exec()
        } Catch(e) {
            zn ns
            Throw e
        }
        zn ns

    } catch ex { 
        set sc = ex.AsStatus() 
        write $System.Status.GetErrorText(sc),! 
        do $SYSTEM.Process.Terminate($JOB,1) 
    } 
    quit sc
}

/// Create web application
ClassMethod CreateWebApp(pNamespace As %String, pWebApp As %String, pDispatch As %String) As %Status
{
  set ret = $$$OK
  try {
    zn "%SYS" 
    set webName = pWebApp 
    set webProperties("DispatchClass") = pDispatch 
    set webProperties("NameSpace") = pNamespace 
    set webProperties("Enabled") = 1 
    set webProperties("AutheEnabled") = 32 
    $$$ThrowOnError(##class(Security.Applications).Create(webName, .webProperties))

  } catch ex {
    set ret = ex.AsStatus()
  } 
  quit ret
}

}
