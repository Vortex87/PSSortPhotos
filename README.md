# PSSortPhotos

Sorting Photos  by powershell to directory named YYYY\YYYY-MM-DD.

Script search all the photo in source directory and find date of each photo, then sort them.

script will sort photos in order 
YYYY\YYYY-MM-DD%event%\*.jpg
script will take date from exif
script trys to find folders named YYYY-MM-DD* and put photos there and in will create path if not exits
script will find dublicates and renames files if they have the same name but are different,dublicates will be skipped
script can remove photos after sorting
script can require event to create new folders

