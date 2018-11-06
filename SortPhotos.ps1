<#
.decription
script will sort photos in order 
YYYY\YYYY-MM-DD%event%\*.jpg
script will take date from exif
script trys to find folders named YYYY-MM-DD* and put photos there and in will create path if not exits
script will find dublicates and renames files if they have the same name but are different,dublicates will be skipped
script can remove photos after sorting
script can require event to create new folders
.synopsis
sortPhotos.ps1 -searchpath d:\photos\ -targetpath c:\testfolder\  -minsize 1000 -event_req
searchpath path where find photos
targetpath path where is your photos to copy
switch -event_req will require event for every new folder to be created
minsize -minimal size of photos to find in Kb
del -delete photos after sorting



.example
need to sort photos from card
sortPhotos.ps1 -searchpath E:\photos_need_to_sort\ -targetpath C:\sortedphotos\ minsize 200

you can rename created folders but name must like YYYY-MM-DD eventname.

#>
param (
    [Parameter(Mandatory=$True)]
    [string]$searchpath, 
    [Parameter(Mandatory=$True)]
    [string]$targetpath,
    [Switch]$event_req,
    [Parameter(Mandatory=$True)]
    [int]$minsize,
    [switch]$del


)

try {add-type -AssemblyName System.Drawing}
catch {write-warning "System.Drawing is not installed, install .netframework 4 of higher"
return}




    if (!(test-path -path $searchpath)) {write-warning "no search folder found"
    return}
 



 if (!(test-path -path $targetpath)) {write-warning "no target path found"
 
 return}
 #приведем введеную папку к корректному виду.
 if (!($targetpath.endswith("\"))){$targetpath = $targetpath+"\"}
#обнулим все переменные
$i = 0
$newfoldercount = 0 #создано новых папок
$photoscopied = 0 #всего фоток скопировано
$event = $null #обнулим название события
$photoslike = 0 #количество фотографий с одинаковой датой и именем файла но разных по размеру
$skipped = 0 #пропущено по причине того что они уже есть в целевой папке



if($minsize){
    $files = Get-ChildItem -Include *.jpg -Path $searchpath -Recurse | where {$_.Length -gt ($minsize*1kb)}
    }
else    {
    $files = Get-ChildItem -Include *.jpg -Path $searchpath -Recurse
    }

$photoscount = $files.Count
$weight = $files | measure -Property length -Sum 
$weight = [math]::round($weight.Sum/1Mb,2)
write-host "TotalPhotos in source $photoscount"
Write-Host "TotalSize $weight Mb"


foreach ($item in $files){
$itemfullname = $item.FullName
write-host $itemfullname
#пробуем вытащить дату фотки из exif
try {
$file = New-Object System.Drawing.Bitmap($itemfullname)
$exifdate = [System.Text.Encoding]::ASCII.GetString($file.GetPropertyItem(36867).Value)
#$nfname = [datetime]::ParseExact($pdate,"yyyy:MM:dd HH:mm:ss`0",$null).ToString('yyyyMMdd HH_mm_ss')
$filedate = [datetime]::ParseExact($exifdate,"yyyy:MM:dd HH:mm:ss`0",$null).ToString('yyyy-MM-dd')
$file.Dispose()
}
catch {write-host "no  date in exif. Filedate will be used " -NoNewline
$filedate = $item.lastwritetime.ToString('yyyy-MM-dd') }

# расладываем фотографию по папам.
# сначала проверяем есть ли такая папка вообще в целевой, если есть, то будем копировать туда
$dest = gci $targetpath -Directory -Recurse| where {$_.name.Contains($filedate)}
$year = $filedate.remove(4)
#если папка такая не найдена, то будем создавать новую.
if (!$dest){
    write-host "there is no pholder for item, need to create"  -ForegroundColor green
    if ($event_req) {
    $event = read-host "Specify event of photo $filedate"}
    if ([string]::IsNullOrWhiteSpace($event)) {$dest = $targetpath+$year+"\"+$filedate+"\"}
    else {$dest = $targetpath+$year+"\"+$filedate +" "+ $event+ "\"}
    write-host "Create path $dest"
    New-Item -Path $dest -ItemType directory
    $newfoldercount++
    write-host "Copiing $item в $dest"
    
    Copy-Item  "$item" -Destination "$dest"
}
else {
    #так как папка такая уже существует то
    $destpath = $dest.fullname
    #необходимо проверть вдруг там этот файл уже есть запускаем процедуру сравнения файлов
    if (test-path ($destpath+'\'+$item.Name)) {
        #файл существует
        Write-Host "такой файл уже есть"
        #сравниваем файлы, если отличаются то будем переименовывать (сравнение будем производить по размеру файла)
        $filetest = $destpath+'\'+$item.Name
        $exsistingfile = get-item $filetest
        if (($item.Length - $exsistingfile.Length) -eq 0) {write-host "File exists - skipping."; $skipped++}
            else {
            #файлы разные необхоидмо уточнить, не коировали ли мы такой файл ранее даже с другим именем. Сравним по размеру и дате (маловероятное совпадение)
                if((Get-ChildItem -Include *.jpg -Path $destpath -Recurse |  where {$_.length -eq $item.length} | measure).count -gt 0){
                write-host "Found same file with another name"}
                else {
            #файлы разные будем копировать с разными именами
            $newname = $destpath+"\"+$item.name.Insert($item.name.LastIndexOfAny("."),"_"+(Get-Random -Maximum 99 -Minimum 10))
            copy-Item  $item -Destination "$newname"
            $photoscopied++
            $photoslike++
            }}
        }

    else {
        #просто копируем файл
        $destpath = $dest.fullname
       copy-Item  $item -Destination "$destpath"
       $photoscopied++

}
}

$i++
write-host "$i из $photoscount"
}

Write-host "Found photos in source $i"
Write-Host "New Folders created $newfoldercount                                                                                                           "
Write-Host "TotalCopied $photoscopied"
write-host "renamed $photoslike"
write-host "Skipped $skipped"

if ($del) {write-host "Removing Sorted..."
foreach ($item in $files) {Remove-Item $item -ErrorAction SilentlyContinue
}
write-host "SortedPhotos deleted"
}
