# Action-MsixBundler
This Action lets you pass a folder containing multiple individual `.msix` files and bundles them into a single `.msixbundle` file.

There are a few samples below to help you get started. However, I recommend you visit the official repository's [main.yml](https://github.com/LanceMcCarthy/Action-MsixBundler/blob/main/.github/workflows/main.yml) workflow to see the real-world bundling example.

> **This Action only works on Windows runners**! This should not be a problem because you will not be compiling and bundling MSIX files on non-windows platforms anyways.

## Inputs

Below are the action's inputs that need to be defined in the Action's `with` block.

| Required | Input | Default Value | Summary |
|----------|--------|---------|---------|
| ✔ | `msix-folder` | none | The absolute path to the folder containing all the MSIX files to be bundled. |
| ✔ | `msixbundle-filepath` | none| The absolute file path to be used for the .msixbundle. For example, C:\MyFolder\MyApp_1.0.0.0_x86_x64.msixbundle. |
| ✔ | `msixbundle-version` | 0.0.0.0 | Specifies the version number of the bundle. The version number MUST be in four parts separated by periods in the form: `<Major>.<Minor>.<Build>.<Revision>`. |
|  | `architecture` | x86 | The architecture version of MakeAppx.exe and SignTool.exe to use. |
|  | `sdk-version` | 10.0.19041.0 | The version of MakeAppx.exe and SignTool.exe to use. |
|  | `enable-bundle-signing` | false | Enables signing of the msixbundle by using signTool.exe after the bundle is created (the individual msix files do not need to be signed fore this to work) |
|  | `certificate-path` | none | Path to the code signing certificate (i.e., the PFX file). This value must be set if you have enabled signing. |
|  | `certificate-private-key` | none | The private key (password) for the PFX. This value must be set if you have enabled signing. |
|  | `signing-hash-algorithm` | SHA256 | The hash algorithm used for signing (default is SHA256). |

## Outputs

The action will copy the file path to an output variable that you can use in subsequent workflow steps

| Output | Default Value | Summary |
|----------|--------|---------|---------|
| `msixbundle_path` | none | The absolute file path to the msixbundle file. |

In the following example, notice how the step has the id of `bundler`. In the next step, we can get the output value of `msixbundle_path` using the `${{ steps.bundler.outputs.msixbundle_path }}` syntax.

```yaml
  - name: Make msixbundle
    id: bundler
    uses: LanceMcCarthy/Action-MsixBundler@v1.0.0
      ...
  
  - name: Verify msixbundle File Path
    shell: pwsh
    run: |
      $path_to_my_msix_bundle = "${{ steps.bundler.outputs.msixbundle_path }}"
      Write-Output $path_to_my_msix_bundle
```

## Examples

Here are a couple examples to get you started. 

> If you copy-paste from any example, don't forget to use a real version number at the end of action name. For example, `LanceMcCarthy/Action-MsixBundler@v1.0.0` instead of `LanceMcCarthy/Action-MsixBundler@vX.X.X`.

### Bundle and Sign(most common)

The most common expected use of this is to bundle all the msix files and then sign the final msixbundle file. In the following example, you are expected to have all your individual msix files in the `"C:\MyApp\OnlyMsixFilesFolder"` folder.

```yaml
  - name: Load PFX File from GitHub Secrets
    id: savepfx
    shell: pwsh
    run: |
      $pfx_cert_byte = [System.Convert]::FromBase64String("${{ secrets.PFX_BASE64 }}")
      $currentDirectory = Get-Location
      $certificatePath = Join-Path -Path $currentDirectory -ChildPath "MyCertificate.pfx"
      [IO.File]::WriteAllBytes("$certificatePath", $pfx_cert_byte)
      # output the file path as a variable
      echo "::set-output name=cert_path::$certificatePath"
      
  - name: Make msixbundle
    id: bundler
    uses: LanceMcCarthy/Action-MsixBundler@vX.X.X
    with:
      msix-folder: "C:\MyApp\OnlyMsixFilesFolder"
      msixbundle-filepath: "C:\MyApp\MyApp_1.0.0.0_x86_x64.msixbundle"
      msixbundle-version: "1.0.0.0"
      enable-bundle-signing: true
      certificate-path: ${{ steps.savepfx.outputs.cert_path }}
      certificate-private-key: ${{ secrets.PFX_PRIVATE_KEY }}
      
  - name: Verify msixbundle File Path
    shell: pwsh
    run: |
      $path_to_my_msix_bundle = ${{ steps.bundler.outputs.msixbundle_path }}"
      Write-Output $path_to_my_msix_bundle
```

> If you would like to see some Powershell script exampel that finds all the msix files and copies them into a folder, visit 

### Bundle without Signing

If you want to just bundle everything without signing, it just pass the three required inputs.

```yaml

  - name: Make msixbundle
    id: bundler
    uses: LanceMcCarthy/Action-MsixBundler@v1.0.0
    with:
      msix-folder: "C:\MyApp\OnlyMsixFilesFolder"
      msixbundle-filepath: "C:\MyApp\MyApp_1.0.0.0_x86_x64.msixbundle"
      msixbundle-version: "1.0.0.0"
      
  - name: Verify msixbundle File Path
    shell: pwsh
    run: |
      $path_to_my_msix_bundle = ${{ steps.bundler.outputs.msixbundle_path }}"
      Write-Output $path_to_my_msix_bundle
```


## Important

If you need to use a environment variable for a `with` input, you must use the `${{ env.Name }}` syntax and **not** `$env:Name`. See [Github Contexts](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts) documentation for more help.

### Using Environment Variables

For example:

```yaml
with:
  property-name: $env:MyVariable # Does NOT work for inputs
  property-name: ${{ env.MyVariable }} # Works.
```

### Using Output Variables (recommended)

It is safer and more reliable if you use a job **output** variable from a previous job. In the following example, the `create-color` job has a `selected_color` output variable. That output variable can be used in a later job.

```yaml
  - id: create-color
    shell: pwsh
    run: |
      $color = "Green"
      echo "::set-output name=selected_color::$color"
      
  - id: bundler
    uses: LanceMcCarthy/Action-MsixBundler@v1.0.0
    with:
      property-name: ${{ steps.create-color.outputs.selected_color }}
```
This is the option GitHub recommends instead of using job-wide environment variables that may contain sensitive information.

