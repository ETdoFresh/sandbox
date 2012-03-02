<?php
define("THUMBS", "thumbnails/"); // Thumbnail directory
define("FOLDER", "folder.png"); // Folder image

class PictureViewer {
	// Member Variables
	private $path;
	private $files = array();
	private $directories = array();
	
	// Constructor
	public function PictureViewer($path = "./") {
		$this->path = $path;
		if ($handle = opendir($path)) {
			while (false !== ($file = readdir($handle))) {
				if (is_file($path.$file) and $file != FOLDER) {
					$this->files[] = $file;
				} elseif (is_dir($path.$file) and $file."/" != THUMBS) {
					if ($file != "." and $file != "..") {
						$this->directories[] = $file;
					}
				}
			}
			closedir($handle);
		}
	}
	
	// Returns an array of image filenames
	public function getImages($start = 0, $limit = 100) {
		$id = 0;
		$images = array();
		foreach ($this->files as $value) {
			if (stripos($value, ".png") !== false
			or stripos($value, ".jpg") !== false
			or stripos($value, ".jpeg") !== false) {
				if ($id >= $start) $images[] = $value;
				if ($id >= $limit+$start-1) break;
				$id++;
			}
		}
		return $images;
	}
	
	// Creates and returns an array of thumbnails
	public function getThumbnails($start = 0, $limit = 100, $width = 80, $height = 80) {
		$images = $this->getImages($start, $limit);
		if(!is_dir($this->path.THUMBS) and sizeof($images) > 0) {
			mkdir($this->path.THUMBS);	
		}
		foreach ($images as $i => $image) {
			//Update images array with thumbnails
			$images[$i] = THUMBS.$image;
			if (!file_exists($this->path.THUMBS.$image)) {
				// Create image
				if (stripos($image, ".jpg") !== false
				or stripos($image, ".jpeg") !== false) {
					$src_image=imagecreatefromjpeg($this->path.$image);
				} elseif (stripos($image, ".png") !== false) {
					$src_image=imagecreatefrompng($this->path.$image);
				}
				// Size image
				$src_w=imageSX($src_image);
				$src_h=imageSY($src_image);
				if ($src_w > $src_h) {
					$dst_w=$width;
					$dst_h=$src_h*($height/$src_w);
				}
				if ($src_w < $src_h) {
					$dst_w=$src_w*($width/$src_h);
					$dst_h=$height;
				}
				if ($src_w == $src_h) {
					$dst_w=$width;
					$dst_h=$height;
				}
				// Resample Image
				$dst_image=ImageCreateTrueColor($dst_w,$dst_h);
				imagecopyresampled($dst_image,$src_image,0,0,0,0,$dst_w,$dst_h,$src_w,$src_h);
				// Write Image
				if (stripos($image, ".jpg") !== false
				or stripos($image, ".jpeg") !== false) {
					imagejpeg($dst_image,$this->path.THUMBS.$image);
				} elseif (stripos($image, ".png") !== false) {
					imagepng($dst_image,$this->path.THUMBS.$image);
				}
				// Clear Cache
				imagedestroy($dst_image); 
				imagedestroy($src_image);
			}
		}
		return $images;
	}
	
	// Returns an array of arrays that contains: name, link, thumb
	public function getImageArray($start = 0, $limit = 100, $width = 80, $height = 80) {
		$dirs = $this->directories;
		$images = $this->getImages($start, $limit);
		$thumbs = $this->getThumbnails($start, $limit, $width, $height);
		
		$imgArray = array();
		foreach ($dirs as $dir) {
			$link = basename($_SERVER['PHP_SELF'])."?dir=".$this->path.$dir."/";
			$imgArray[] = array("name" => $dir, "link" => $link, "thumb" => FOLDER);
		}
		for ($i = 0; $i < sizeof($images); $i++) {
			$name = $images[$i];
			$link = $this->path.$images[$i];
			$thumb = $this->path.$thumbs[$i];
			$imgArray[] = array("name" => $name, "link" => $link, "thumb" => $thumb);
		}
		
		return $imgArray;
	}
}
?>