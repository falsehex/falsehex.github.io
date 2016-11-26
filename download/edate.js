/* edate.js - Version 1.0  26 Mar 14
   eDate - HTML Input Date Change Via Mouse Scroll
   Copyright 2012-2014 Del Castle

   Include "<script type='text/javascript' src='edate.js'></script>"
   Add "class='edate'" to input tag, e.g. "<input class='edate' type='text' name='time' />"
   Date format: "%Y-%m-%d %H:%M:%S"
*/

posDt = [34, 55, 76, 97, 118];

var objLast = 0;

function leadZero(val)
{
  return (val < 10 ? "0" + val : val);
}

function scrollDate(e)
{
  var objNow = new Date();
  if ((objNow - objLast) > 50)
  {
    var direction = (e.detail > 0 ? -1 : 1);
    var position = e.clientX - this.offsetLeft;
    var regEx = /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
    var aryDt = regEx.exec(this.value);
    if (position < posDt[0]) aryDt[1] = parseInt(aryDt[1], 10) + direction;
    else if (position < posDt[1]) aryDt[2] = parseInt(aryDt[2], 10) + direction;
    else if (position < posDt[2]) aryDt[3] = parseInt(aryDt[3], 10) + direction;
    else if (position < posDt[3]) aryDt[4] = parseInt(aryDt[4], 10) + direction;
    else if (position < posDt[4]) aryDt[5] = parseInt(aryDt[5], 10) + direction;
    else aryDt[6] = parseInt(aryDt[6], 10) + direction;
    var objDt = new Date(aryDt[1], aryDt[2] - 1, aryDt[3], aryDt[4], aryDt[5], aryDt[6]);
    this.value = objDt.getFullYear() + "-" + leadZero(objDt.getMonth() + 1) + "-" + leadZero(objDt.getDate()) + " " + leadZero(objDt.getHours()) + ":" + leadZero(objDt.getMinutes()) + ":" + leadZero(objDt.getSeconds());
    objLast = objNow;
  }
}

function eDate()
{
  var aryInputs = document.getElementsByTagName("input");
  for (var input = 0; input < aryInputs.length; input++)
  {
    if (aryInputs[input].className.search("edate") != -1) aryInputs[input].addEventListener("DOMMouseScroll", scrollDate);
  }
}

document.addEventListener("DOMContentLoaded", eDate);
