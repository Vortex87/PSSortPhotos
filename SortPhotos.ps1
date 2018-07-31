<#
Скрипт автоматически сортирует фотки в соотвествии с порядком ГГГГ\ГГГГММДД событие(если есть)\*.jpg
Сортировка фоток только если они больше 100 кб
Дубликаты копироваться не будут. если фотки будут не дубликатами, но с одинаковым названием, будет присвоено новое имя.
методика сравнения файлов размер и дата
По окончании предложит удалить отсортированные фотки.
на каждый день будет создана отдельная папка, если папка уже есть файлы будут помещены в неё
#>
try {add-type -AssemblyName System.Drawing}
catch {write-host "отсутсвует необходимый модуль"
return}
finally {}
$searchfolder = read-host "Укажите папку где искать фотки. Поиск будет искать все фотки в папке с файлами более 200 кб."
if (!$searchfolder) {write-host "Необходимо указать папку где искать фотки";read-host 
return}
else {
    if (!(test-path -path $searchfolder)) {write-host "Но такой папки нету...";Read-Host
return}}
 
$targetpath = read-host "Укажите папку куда складывать отсортированные фотки"
if (!$targetpath) {write-host "необходим указать путь куда складывать отсортированные фотки";read-host
return}
 else {
 if (!(test-path -path $targetpath)) {write-host "Но такой папки нету..."
 read-host
 return}}
 #приведем введеную папку к корректному виду.
 if (!($targetpath.endswith("\"))){$targetpath = $targetpath+"\"}
#обнулим все переменные
$i = 0
$newfoldercount = 0 #создано новых папок
$photoscopied = 0 #всего фоток скопировано
$event = $null #обнулим название события
$photoslike = 0 #количество фотографий с одинаковой датой и именем файла но разных по размеру
$skipped = 0 #пропущено по причине того что они уже есть в целевой папке
write-host "Спрашивать событие при создании новой папки?" -ForegroundColor Green
write-host "1. спрашивать"
write-host "2. не спрашивать"
$event_req = Read-host "Выберите пункт меню"
Switch($event_req){
1{Write-Host "При каждом новом запросе будет создан запрос события" -ForegroundColor Green}
2{Write-Host "Событие запрашиваться не будет" -ForegroundColor Green}
default{write-host "Событие запрашиваться не будет"}
}


#$item =get-item "g:\photos\testkw\20170729-_MG_0325_1.jpg"
$files = Get-ChildItem -Include *.jpg -Path $searchfolder -Recurse | where {$_.Length -gt 200kb}
$photoscount = $files.Count
$weight = $files | measure -Property length -Sum 
$weight = [math]::round($weight.Sum/1Mb,2)
write-host "всего фоток $photoscount"
Write-Host "общий объём $weight Мб"


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
catch {write-host "из exif дату получиь не удалось. будет использована дата файла " -NoNewline
$filedate = $item.lastwritetime.ToString('yyyy-MM-dd') }
finally {
#вытащенная дата фотографии
#Write-Host $filedate
}
# расладываем фотографию по папам.
# сначала проверяем есть ли такая папка вообще в целевой, если есть, то будем копировать туда
$dest = gci $targetpath -Directory -Recurse| where {$_.name.Contains($filedate)}
$year = $filedate.remove(4)
#если папка такая не найдена, то будем создавать новую.
if (!$dest){
    write-host "папки с такой датой нет, будем создавать папку"  -ForegroundColor green
    if ($event_req -ne 2) {
    $event = read-host "укажите название события $filedate"}
    if ([string]::IsNullOrWhiteSpace($event)) {$dest = $targetpath+$year+"\"+$filedate+"\"}
    else {$dest = $targetpath+$year+"\"+$filedate +" "+ $event+ "\"}
    write-host "Создаю папку $dest"
    New-Item -Path $dest -ItemType directory
    $newfoldercount++
    write-host "копирую $item в $dest"
    
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
        if (($item.Length - $exsistingfile.Length) -eq 0) {write-host "это один и тот же файл - пропускаем"; $skipped++}
            else {
            #файлы разные необхоидмо уточнить, не коировали ли мы такой файл ранее даже с другим именем. Сравним по размеру и дате (маловероятное совпадение)
                if((Get-ChildItem -Include *.jpg -Path $destpath -Recurse |  where {$_.length -eq $item.length} | measure).count -gt 0){
                write-host "Найден такой же файл с другим именем в этой папке"}
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

Write-host "Фоток в источнике $i"
Write-Host "Создано новых папок $newfoldercount                                                                                                           "
Write-Host "Всего фоток скопировано $photoscopied"
write-host "Фоток которые пришлось переименовать $photoslike"
write-host "Фоток дубликатов $skipped"
$del = read-Host "Удалить найденные фото Y/n?"
if ($del -eq "y") {write-host "Удаляем файлы"
foreach ($item in $files) {Remove-Item $item -ErrorAction SilentlyContinue
}

write-host "Отсортированные фотки удалены"
}
Else {write-host "ничего не удалено"}
