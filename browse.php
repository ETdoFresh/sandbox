<?php include 'PictureViewer.php';
$path = isset($_GET['dir'])? $_GET['dir'] : "./";
$tSize = 100;
$picView = new PictureViewer($path);
$imgArray = $picView->getImageArray(0,100,$tSize,$tSize);
foreach ($imgArray as $img) {
?>
	<div style="float:left; text-align:center; padding:1em 1em">
	<div style="line-height:<?php echo $tSize?>px; font-size:0px;">
		&nbsp;<a href="<?php echo $img["link"];?>">
			<img style="vertical-align:middle;" src="<?php echo $img["thumb"];?>" />
		</a>&nbsp;
	</div>
	<div style="font-family:Verdana, Geneva, sans-serif; font-size:0.8em;"><?php echo $img["name"];?></div>
	</div>
<?php	
}
?>