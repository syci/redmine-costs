//-- copyright
// OpenProject Costs Plugin
//
// Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//++

function initialize_editinplace(cancelButtonAttributes) {
  _cancelButtonAttributes = cancelButtonAttributes;
}

function getCurrencyValue(str) {
  var result = str.match(/^\s*(([0-9]+[.,])+[0-9]+) (.+)\s*/);
  return result ? new Array(result[1], result[3]) : new Array(str, "");
}

function makeEditable(id, name){
  var obj = $(id);
  obj.addClassName("inline_editable");
  Event.observe(id, 'click', function(){edit_and_focus(obj, name)});
  
}

function edit_and_focus(obj, name) {
  edit(obj, name);
  
  Form.Element.focus(obj.id+'_edit');
  Form.Element.select(obj.id+'_edit');
}

function edit(obj, name, obj_value) {
  Element.hide(obj);

  var obj_value = typeof(obj_value) != 'undefined' ? obj_value : obj.innerHTML;
  var parsed = getCurrencyValue(obj_value);
  var value = parsed[0];
  var currency = parsed[1]
  
  var span_in = '<span id="'+obj.id+'_editor">'
    var text = '<input id="'+obj.id+'_edit" name="'+name+'" size="7" value="'+value+'" class="currency" /> '+currency;
    var button = '<input id="'+obj.id+'_cancel" type="image" '+ _cancelButtonAttributes  +' /> ';
  var span_end = '</span>';
  
  new Insertion.After(obj, span_in+text+button+span_end);

  Event.observe(obj.id+'_cancel', 'click', function(){cleanUp(obj)});
}

function cleanUp(obj){
  Element.remove(obj.id+'_editor');
  Element.show(obj);
}
