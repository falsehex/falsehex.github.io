/* esort.js - Version 1.0.2  22 Dec 16
   eSort - HTML Table Sort
   Copyright 2012-2016 Del Castle

   Include "<script type='text/javascript' src='esort.js'></script>"
   Add "class='esort'" to table tag, e.g. "<table class='esort'>"
*/

var colFirst = 0;

function sortTable(objTable, column)
{
  if (objTable.rows.length > 2)
  {
    var cnt;
    var strSort;
    var arySort = [];
    for (cnt = 1; cnt < objTable.rows.length; cnt++) arySort.push(objTable.rows[cnt].cells[column].textContent);
    if (isNaN(arySort[0])) arySort.sort();
    else arySort.sort(function(a, b) { return a - b; });
    if (objTable.rows[0].cells[column].textContent.search(/ \u25bc$/) == -1)
    {
      arySort.reverse();
      strSort = " \u25bc";
    }
    else strSort = " \u25b2";
    for (cnt = colFirst; cnt < objTable.rows[0].cells.length; cnt++) objTable.rows[0].cells[cnt].textContent = objTable.rows[0].cells[cnt].textContent.replace(/ (\u25bc|\u25b2)$/, "");
    objTable.rows[0].cells[column].textContent += strSort;
    while (arySort.length)
    {
      strSort = arySort.pop();
      for (cnt = 1; cnt < (arySort.length + 2); cnt++)
      {
        if (objTable.rows[cnt].cells[column].textContent == strSort)
        {
          objTable.appendChild(objTable.rows[cnt]);
          break;
        }
      }
    }
  }
}

function eSort()
{
  var cnt;
  var aryTables = document.getElementsByTagName("table");
  for (var table = 0; table < aryTables.length; table++)
  {
    if (aryTables[table].className.search("esort") != -1)
    {
      for (cnt in aryTables[table].rows[0].cells)
      {
        if (cnt >= colFirst) aryTables[table].rows[0].cells[cnt].onclick = function() { sortTable(this.parentNode.parentNode, this.cellIndex); }
      }
    }
  }
}

document.addEventListener("DOMContentLoaded", eSort);
