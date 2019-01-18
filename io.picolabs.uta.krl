ruleset io.picolabs.uta {
  meta {
    shares __testing, initialize, stopCode, timeConvert, minDiff
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "initialize" }
      , { "name": "timeConvert" }
      , { "name": "minDiff" }
      , { "name": "stopCode", "args": [ "code" ] }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ { "domain": "init", "type": "stops" }
        //,{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    app = {"name":"UTA","version":"0.0"/* img: , pre: , ..*/};
     bindings = function(){
      {
        //currently no bindings
      };
    }
    
    initialize = function() {
      resp = http:get(<<https://raw.githubusercontent.com/KandareJ/UTA/master/mach 3.txt>>){"content"}.split(re#\n#);//gets the file from github
      header = resp[0].split(re#,#);//creates the headers
      body = resp.splice(0,1).splice(resp.length()-1,1);// gets the body
      
      
      body.map(function(x) {
        info = x.split(",").slice(0,3);
        
        map = x.extract(re#(\{.*?\})#)[0];
        list = map.extract(re#(.*? : \[.*?\])#g);
        timesMap = list.map(function(x){x.substr(1)}).map(function(x){
          k = x.extract(re#(\".*?\")#);//picks out the route name to be used as the key
          v = x.extract(re#(\[.*?\])#);//picks out the array for the value
          v2 = v[0].substr(1,v.length()-2).split(",");//splits the array string into an actual array
          v3 = v2.slice(0, v2.length()-2).sort(function(a,b){
            (a.length() < b.length())  => -1 | a.length() > b.length() =>  1 | a cmp b
          });//cuts out the empty element
          {}.put(k[0].substr(1,k[0].length()-2), v3);//makes the map and puts it into an array
        }).reduce(function(a,b){ a.put(b) }); //the reduce changes it from an array of maps with only one key value pair to one big map
        
        all = info.append(timesMap);
        [header, all].pairwise(function(a,b){ {}.put(a,b) }).reduce(function(a,b){a.put(b)})
      });
    }
    
    timeConvert = function(tString = "10:02:12") {
      wocol = tString.extract(re#[0-9]#g).join("") + "Z";
      
      toRet = time:add((wocol.length() == 6) => "0"+wocol | wocol, { "hours" : 7 });
      
      toRet;
    }
    
    timeCompare = function(time1, time2) {
      (stampConvert(time1) > stampConvert(time2)) => true | false;
    }
    
    stampConvert = function(toConv = time:now()) {
      toConv.substr(11,12).extract(re#[0-9|\.]#g).join("").as("Number");
    }
    
    stopCode = function(code) {
      code.klog("Value:");
      temp = ent:store.filter(function(x) { x{"Code"} == code })[0];
      temp["RoutesArray"] = temp["RoutesArray"].map(function(x) {
        x.filter(function(y) {
          timeCompare(timeConvert(y), time:now());
        });
        
        
      }).map(function(x){ x.append(minDiff(timeConvert(x[0]))) });
      temp/*["RoutesArray"].map(function(x){
        x.append(minDiff(timeConvert(x[0])))
      })*/
    }
    
    minDiff = function(time) {
      h1 = time.substr(11,2).as("Number");
      h2 = time:now().substr(11,2).as("Number");
      m1 = time.substr(14,2).as("Number");
      m2 = time:now().substr(14,2).as("Number");
      (h1 - h2) * 60 + (m1 - m2) + " min"
    }
    
    
  }
  
    rule discovery { select when manifold apps send_directive("app discovered...", {"app": app, "rid": meta:rid, "bindings": bindings(), "iconURL": "https://image.flaticon.com/icons/svg/201/201616.svg"} ); }
  
  
  rule initializeStops {
    select when init stops
    
    always{
      ent:store := initialize();
    }
    
  }
  
}
