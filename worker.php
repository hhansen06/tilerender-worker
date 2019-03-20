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

        $cmd = "python /home/renderer/src/Nik4/nik4.py -s ".$data->req->scale." -c ".$data->req->x." ".$data->req->y." -z ".$data->req->zoom
        ." -p ".$data->req->ppi." --size-px ".$data->req->width." ".$data->req->height." ".$mapnikurl." /tmp/".$id.".png";


        echo $cmd;
        exec($cmd);
        if($data->req->cross == "true")
        {

               $width = $data->req->width;
               $height = $data->req->height;

                $im2 = @imagecreatefrompng("/tmp/".$id.".png");
                $im = imagecreatetruecolor($width, $height) or die("Cannot Initialize new GD image stream");
                imagecopyresampled($im,$im2,0,0,0,0, $width,$height,$width,$height);

                $red = imagecolorallocate($im, 255, 0, 0);      // red
                $posw = ($width/2)-5;
                $posh = ($height/2)-5;
                imageline($im, $posw,$posh,$posw+10,$posh,$red);
                imageline($im, $posw+5,$posh-5,$posw+5,$posh+5,$red);
                imagepng($im,"/tmp/".$id.".png");
                imagedestroy($im);
        }
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
