Import-Module SmbShare
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# result フォルダのパスをスクリプトと同じ階層に変更
$resultFolder = Join-Path $scriptDir "result"
$inputFilePath = Get-ChildItem -Path $scriptDir -Filter path.txt
$outputFile = Join-Path $resultFolder "共有アクセス権.csv"
$outputFile2 = Join-Path $resultFolder "NTFS権.csv"
$folders = Get-Content $inputFilePath

Set-Content $outputFile "共有権限"
Set-Content $outputFile2 "NTFS権限"

$titleShare = @("パス", "共有名", "ユーザ/グループ", "フルコン", "変更", "読取")
foreach ($item in $titleShare) {
    Add-Content $outputFile -Value "$($item)," -NoNewline
}
Add-Content $outputFile -Value ""

$titleNTFS = @("パス","ユーザ/グループ","フルコン","変更","読取実行","フォ表示","読取","書込","特殊","適用先")
foreach ($item in $titleNTFS) {
    Add-Content $outputFile2 -Value "$($item)," -NoNewline
}
Add-Content $outputFile2 -Value ""

$shareNames = @()
$sharePaths = @()

# ----- 共有 ------

# 共有設定を取得
$shareInfo = Get-SmbShare -Special $false

foreach ($share in $shareInfo) {
    $shareNames += $share.Name
    $sharePaths += $share.Path
}
# 各フォルダに対して処理を行う
foreach ($folderPath in $folders) {
    Add-Content $outputFile -Value "$($folderPath)" -NoNewline
    Add-Content $outputFile2 -Value "$($folderPath)" -NoNewline

    # 共有名
    if ($sharePaths.Contains($folderPath)) {

        # 共有タイトル
        <#
        foreach ($item in $shareExcel) {
            Add-Content $outputFile -Value "$($item)," -NoNewline
        }
        Add-Content $outputFile -Value ""
        #>

        $indexOfDuplicates = @()
        $currentIndex = 0
        while ($currentIndex -lt $sharePaths.Length) {
            $currentIndex = [array]::IndexOf($sharePaths, $folderPath, $currentIndex)
            if ($currentIndex -eq -1) { 
                break
            }
    
            $indexOfDuplicates += $currentIndex
            $currentIndex++
        }

        foreach ($indexOfDuplicate in $indexOfDuplicates) {
            Add-Content $outputFile -Value ",$($shareNames[$indexOfDuplicate])," -NoNewline
            $shareAccesses = Get-SmbShareAccess -Name $shareNames[$indexOfDuplicate]
            for ($j = 0; $j -lt $shareAccesses.AccountName.Count; $j++) {
                $s = $shareAccesses[$j]
                if ($j -ge 1) {Add-Content $outputFile -Value " , ,$($s.AccountName)," -NoNewline}
                else{Add-Content $outputFile -Value "$($s.AccountName)," -NoNewline}
                $kengen = $s.AccessRight
                if ($s.AccessRight -eq "Full") {
                    Add-Content $outputFile -Value "■," -NoNewline
                    Add-Content $outputFile -Value "■," -NoNewline
                    Add-Content $outputFile -Value "■,"
                }
                elseif ($s.AccessRight -eq "Change") {
                    Add-Content $outputFile -Value "□," -NoNewline
                    Add-Content $outputFile -Value "■," -NoNewline
                    Add-Content $outputFile -Value "■," 
                }
                elseif ($s.AccessRight -eq "Read") {
                    Add-Content $outputFile -Value "□," -NoNewline
                    Add-Content $outputFile -Value "□," -NoNewline
                    Add-Content $outputFile -Value "■,"
                }
            }
        }
    } else {
        Add-Content $outputFile -Value ",なし"
    }

    # ----- 共有終 -----
 
    # NTFS権限を取得
    $acl = Get-Acl -Path $folderPath
 
    # NTFSアクセス権をログに書き込み
    foreach ($ace in $acl.Access) {
        
        if (($ace.IdentityReference.toString() -eq "CREATOR OWNER") -or ($ace.IdentityReference.toString() -eq "BUILTIN\Users")){
            continue
        }
        Add-Content $outputFile2 -Value ",$($ace.IdentityReference)," -NoNewline
<#
        $syurui = $ace.AccessControlType
        if ($syurui -eq "Allow") {
            $output += "許可,"
        } else {
            $output += "拒否"
        }
#>
        $k = $ace.FileSystemRights.ToString().Split(",")
        $kengens = @("□","□","□","□","□","□","□")
        foreach ($kengen in $k) {
            $kengen = $kengen -replace " ", ""
            
            if ($kengen -eq "Synchronize") {
                continue
            }
            $output = ""
            if ($kengen -eq "FullControl") {
                foreach ($i in 0..5) {
                    $kengens[$i] = "■"
                }
            } else {
                if($kengen -eq "Modify") {
                    foreach ($i in 1..6) {
                        $kengens[$i] = "■"
                    }
                } else {
                    if ($kengen -eq "Read") {
                        $kengens[4] = "■" 
                        
                    }
                    if ($kengen -eq "ReadAndExecute") {
                        $kengens[2] = "■"
                        $kengens[3] = "■"
                        $kengens[4] = "■"
                    }
                    if ($kengen -eq "Write") {
                        $kengens[5] = "■"
                    }
                    if (($kengen -ne "Read") -and ($kengen -ne "ReadAndExecute") -and ($kengen -ne "Write")) {
                        $kengens[6] = "■"
                    }
                }
            }

            for($i = 0; $i -lt $kengens.Count; $i++){
                $output += "$($kengens[$i]),"
            }
        }
        Add-Content $outputFile2 -Value $output -NoNewline


        if ($ace.InheritanceFlags.ToString().Split(",").Length -eq 1) {
            Add-Content $outputFile2 -Value "このフォルダとサブフォルダ"
        } else {
            Add-Content $outputFile2 -Value "このフォルダとサブフォルダ およびファイル"
        }
    }
}