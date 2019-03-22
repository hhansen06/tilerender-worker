<?php

echo "Working on File: ".$argv[1];
copy($argv[1],$argv[1].".orig");


$xml = simplexml_load_file($argv[1]);



$s1 = $xml->addChild("Style");
$s1->AddAttribute("name","geoms");
$s1r1 = $s1->addchild("Rule");

$s1r1->addchild("Filter","[mapnik::geometry_type]=polygon or [fill]");
$ps = $s1r1->addchild("PolygonSymbolizer");
$ps->addAttribute("fill","[fill]");
$ps->addAttribute("fill-opacity","[fill-opacity]");

$s1r1 = $s1->addchild("Rule");

$s1r1->addchild("Filter","[mapnik::geometry_type]=linestring or [stroke]");
$ps = $s1r1->addchild("LineSymbolizer");
$ps->addAttribute("stroke","[stroke]");
$ps->addAttribute("stroke-width","[stroke-width]");
$ps->addAttribute("stroke-opacity","[stroke-opacity]");

####################


$s1 = $xml->addChild("Style");
$s1->AddAttribute("name","points");
$s1->AddAttribute("filter-mode","first");
$s1r1 = $s1->addchild("Rule");

$s1r1->addchild("Filter","[mapnik::geometry_type]=point and [marker-path]");
$ps = $s1r1->addchild("PointSymbolizer");
$ps->addAttribute("file","[marker-path]");
$ps->addAttribute("allow-overlap","true");
$ps->addAttribute("transform","scale(0.5)");

$ll = $xml->addChild("Layer");
$ll->addAttribute("name","route");
$ll->addAttribute("status","off");
$ll->addAttribute("srs","+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs");
$ll->addChild("StyleName","geoms");
$ll->addChild("StyleName","points");
$ds = $ll->addChild("Datasource");
$type = $ds->addChild("Parameter","geojson");
$type->addAttribute("name","type");

$type = $ds->addChild("Parameter",'${route}');
$type->addAttribute("name","file");
file_put_contents($argv[1],$xml->asXML());
?>
