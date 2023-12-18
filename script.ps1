Import-Module SmbShare
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# result �t�H���_�̃p�X���X�N���v�g�Ɠ����K�w�ɕύX
$resultFolder = Join-Path $scriptDir "result"
$inputFilePath = Get-ChildItem -Path $scriptDir -Filter path.txt
$outputFile = Join-Path $resultFolder "���L�A�N�Z�X��.csv"
$outputFile2 = Join-Path $resultFolder "NTFS��.csv"
$folders = Get-Content $inputFilePath

Set-Content $outputFile "���L����"
Set-Content $outputFile2 "NTFS����"

$titleShare = @("�p�X", "���L��", "���[�U/�O���[�v", "�t���R��", "�ύX", "�ǎ�")
foreach ($item in $titleShare) {
    Add-Content $outputFile -Value "$($item)," -NoNewline
}
Add-Content $outputFile -Value ""

$titleNTFS = @("�p�X","���[�U/�O���[�v","�t���R��","�ύX","�ǎ���s","�t�H�\��","�ǎ�","����","����","�K�p��")
foreach ($item in $titleNTFS) {
    Add-Content $outputFile2 -Value "$($item)," -NoNewline
}
Add-Content $outputFile2 -Value ""

$shareNames = @()
$sharePaths = @()

# ----- ���L ------

# ���L�ݒ���擾
$shareInfo = Get-SmbShare -Special $false

foreach ($share in $shareInfo) {
    $shareNames += $share.Name
    $sharePaths += $share.Path
}
# �e�t�H���_�ɑ΂��ď������s��
foreach ($folderPath in $folders) {
    Add-Content $outputFile -Value "$($folderPath)" -NoNewline
    Add-Content $outputFile2 -Value "$($folderPath)" -NoNewline

    # ���L��
    if ($sharePaths.Contains($folderPath)) {

        # ���L�^�C�g��
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
                    Add-Content $outputFile -Value "��," -NoNewline
                    Add-Content $outputFile -Value "��," -NoNewline
                    Add-Content $outputFile -Value "��,"
                }
                elseif ($s.AccessRight -eq "Change") {
                    Add-Content $outputFile -Value "��," -NoNewline
                    Add-Content $outputFile -Value "��," -NoNewline
                    Add-Content $outputFile -Value "��," 
                }
                elseif ($s.AccessRight -eq "Read") {
                    Add-Content $outputFile -Value "��," -NoNewline
                    Add-Content $outputFile -Value "��," -NoNewline
                    Add-Content $outputFile -Value "��,"
                }
            }
        }
    } else {
        Add-Content $outputFile -Value ",�Ȃ�"
    }

    # ----- ���L�I -----
 
    # NTFS�������擾
    $acl = Get-Acl -Path $folderPath
 
    # NTFS�A�N�Z�X�������O�ɏ�������
    foreach ($ace in $acl.Access) {
        
        if (($ace.IdentityReference.toString() -eq "CREATOR OWNER") -or ($ace.IdentityReference.toString() -eq "BUILTIN\Users")){
            continue
        }
        Add-Content $outputFile2 -Value ",$($ace.IdentityReference)," -NoNewline
<#
        $syurui = $ace.AccessControlType
        if ($syurui -eq "Allow") {
            $output += "����,"
        } else {
            $output += "����"
        }
#>
        $k = $ace.FileSystemRights.ToString().Split(",")
        $kengens = @("��","��","��","��","��","��","��")
        foreach ($kengen in $k) {
            $kengen = $kengen -replace " ", ""
            
            if ($kengen -eq "Synchronize") {
                continue
            }
            $output = ""
            if ($kengen -eq "FullControl") {
                foreach ($i in 0..5) {
                    $kengens[$i] = "��"
                }
            } else {
                if($kengen -eq "Modify") {
                    foreach ($i in 1..6) {
                        $kengens[$i] = "��"
                    }
                } else {
                    if ($kengen -eq "Read") {
                        $kengens[4] = "��" 
                        
                    }
                    if ($kengen -eq "ReadAndExecute") {
                        $kengens[2] = "��"
                        $kengens[3] = "��"
                        $kengens[4] = "��"
                    }
                    if ($kengen -eq "Write") {
                        $kengens[5] = "��"
                    }
                    if (($kengen -ne "Read") -and ($kengen -ne "ReadAndExecute") -and ($kengen -ne "Write")) {
                        $kengens[6] = "��"
                    }
                }
            }

            for($i = 0; $i -lt $kengens.Count; $i++){
                $output += "$($kengens[$i]),"
            }
        }
        Add-Content $outputFile2 -Value $output -NoNewline


        if ($ace.InheritanceFlags.ToString().Split(",").Length -eq 1) {
            Add-Content $outputFile2 -Value "���̃t�H���_�ƃT�u�t�H���_"
        } else {
            Add-Content $outputFile2 -Value "���̃t�H���_�ƃT�u�t�H���_ ����уt�@�C��"
        }
    }
}