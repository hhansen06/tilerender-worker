<?php
echo "Starting MQTT receiver ...";
require __DIR__ . '/phpMQTT.php';

$server = $argv[1];     // change if necessary
$port = $argv[2];                     // change if necessary
$username = "";                   // set your username
$password = "";                   // set your password
$client_id = "phpMQTT-subscriber"; // make sure this is unique for connecting to sever - you could use uniqid()
$mqtt = new phpMQTT($server, $port, $client_id);
if(!$mqtt->connect(true, NULL, $username, $password)) {
        exit(1);
}
  $topics[$argv[3]] = array("qos" => 0, "function" => "procmsg");
  $mqtt->subscribe($topics, 0);
  while($mqtt->proc()){

  }

$mqtt->close();
function procmsg($topic, $msg){
        echo "Raw:".$msg."\n";
        $data = json_decode($msg);
        print_r($data);
        $id = $data->db->map_id;

        $mapnikurl = "/home/renderer/src/".$data->req->style."/mapnik.xml";

        if(isset($data->req->y) AND isset($data->req->x))
          $center = " -c ".$data->req->x." ".$data->req->y." -z ".$data->req->zoom." ";
        else
          $center = " --fit route ";


        if(isset($data->req->geojson))
        {
          file_put_contents("/tmp/".$id.".geojson",$data->req->geojson);
          $geojson = " --add-layers route --vars route=/tmp/".$id.".geojson ".$center;
        }
        else
        $geojson = $center;
        
                $cmd = "python /home/renderer/src/Nik4/nik4.py ".$geojson." -s ".$data->req->scale
        ." -v --padding ".$data->req->margin." -p ".$data->req->ppi." --size-px ".$data->req->width." ".$data->req->height." ".$mapnikurl." /tmp/".$id.".png";

        echo $cmd;
        exec($cmd);

        if(file_exists("/tmp/".$id.".png"))
        {
          $url = $data->req->uploadurl.$id;
          $ch = curl_init();
          curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
          curl_setopt($ch, CURLOPT_URL, $url);

          $cfile = new CURLFile('/tmp/'.$id.".png",'image/png','map');

          $postData = array(
           'mapfile' => $cfile,
          );

          curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
          $response = curl_exec($ch);
          echo $response;
          echo "Finished!\n";
          unlink("/tmp/".$id.".png");
        }


}

?>

