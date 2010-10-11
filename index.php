<!-- HTML theme from jailbreakme.com -->
<html> 
<head> 
<title>TV Show</title> 
<link rel="stylesheet" type="text/css" media="screen" href="menes.css"/> 
 
<meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no"/> 
<meta name="format-detection" content="telephone=no" /> 
 
<style type="text/css"> 
 
/* All */
 
.question {
        font-weight: bold;
}
 
.question {
        text-align: center;
}
        
a.panel {
        color: #586c90;
        font-weight: bold;
        text-shadow: rgba(255, 255, 255, 0.75) 1px 1px 0;
}
        
.email {
        height: 50px;
        -webkit-text-size-adjust: 140%;
        margin: 0px;
        padding-left: 10px;
        padding-right: 10px;
        width: 100%;
        left: 0px;
}
 
.hidden {
        display: none;
}
 
.warning {
        background-color: #fdd;
}
 
</style> 
 
</head> 
<body class="pinstripe"> 
<div class="panel"> 

<?php

if (empty($_POST['show'])){
	echo '
	
		<fieldset> 
		        <div class="fsd"> 
		                <p class="question">Which TV show would you like to start watching?</p> 
		                <hr /> 
		                <p class="answer"><form method="post" action="'.$_SERVER['PHP_SELF'].'">
							<input type="text" id="show" name="show" style="border: 1px solid black; margin: 10px; width: 250px;" /><br />
							<input type="submit" value="Add Show" style="margin: 10px; height: 40px; width: 250px;" />
						</form></p> 
		        </div> 
		</fieldset>
	';
} else {
	$show = urlencode($_POST['show']);

	// Change these as needed
	$basePath = '/Users/simon/Media/TV Shows';
	$sickBeard = 'http://192.168.0.100:8081';


	// Do not edit past here

	$addShows = '/home/addShows';
	$searchTVDB = $addShows . '/searchTVDBForShowName?name=';
	$addSingleShow = $addShows . '/addSingleShow';

	// Let's query TVDB for the show (using SickBeard)

	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $sickBeard . $searchTVDB . $show);
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	$json = curl_exec($ch);
	curl_close($ch);

	$shows = json_decode($json);

	// TODO: For now, let's assume that the first one is a match

	if (count($shows->results) == 0){
		echo 'Show not found';
		exit;
	} 

	$chosenShow = $shows->results[0];

	// Let's create the folder, using TVDB's name
	$pathToShow = $basePath . '/' . $chosenShow[1];
	mkdir($pathToShow);

	if (!file_exists($pathToShow)){
		echo 'Failed to create directory: ' . $pathToShow;
		exit;
	}

	// And now, let's add it to Sick Beard
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $sickBeard . $addSingleShow);
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
	curl_setopt($ch, CURLOPT_POST, 1 ); 
	curl_setopt($ch, CURLOPT_POSTFIELDS, 'whichSeries=' . $chosenShow[0] . '&skipShow=0&showToAdd=' .  $pathToShow);
	$return = curl_exec($ch);
	$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
	curl_close($ch);	
	echo '
			<fieldset> 
			        <div class="fsd"> 
			                <p class="question">Show Added</p> 
			                <hr /> 
			                <p class="answer" style="text-align: center;">'.$chosenShow[1].'</p> 
			        </div> 
			</fieldset>
	';
}
?>

</div> 
</body> 
</html>