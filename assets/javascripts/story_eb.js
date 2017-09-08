/**************************************
  STORY_EB
***************************************/

RB.StoryEB = RB.Object.create(RB.Issue, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = RB.$(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);
    
    if (RB.permissions.update_stories) {
      j.delegate('.editable', 'click', this.handleClick);
    }
  },

  beforeSave: function(){
    var c = this.$.find('select.assigned_to_id').find(':selected').attr('color');
    var c_light = this.$.find('select.assigned_to_id').find(':selected').attr('color_light');
    // Only change color of task if assigned_to_id has a selected user/group
    if(c!=undefined){
      this.$.css('background-color', c);
      this.$.css('background', '-webkit-gradient(linear, left top, left bottom, from('+c_light+'), to('+c+'))');
      this.$.css('background', '-moz-linear-gradient(top, '+c_light+', '+c+')');
      this.$.css('filter', 'progid:DXImageTransform.Microsoft.Gradient(Enabled=1,GradientType=0,StartColorStr='+c_light+',EndColorStr='+c+')');
    } else {
      this.$.css('background', '-webkit-gradient(linear, left top, left bottom, from(#fee), to(#fd2))');
      this.$.css('background', '-moz-linear-gradient(top, #fee, #fd2)');
      this.$.css('filter', 'progid:DXImageTransform.Microsoft.Gradient(Enabled=1,GradientType=0,StartColorStr=#ffeeee,EndColorStr=#ffdd22)');
    }
  },
  
  editorDisplayed: function(dialog){
    dialog_bgcolor=this.$.css('background-color');
    dialog_bg=this.$.css('background-image');
    if(dialog_bgcolor=='initial'||dialog_bgcolor=='rgba(0, 0, 0, 0)'||dialog_bgcolor=='transparent'){
      // Chrome could not handling background-color css when use -webkit-gradient.
      if(dialog_bg){
        dialog.parents('.ui-dialog').css('background', dialog_bg);      
      } else {
        dialog.parents('.ui-dialog').css('background', '-webkit-gradient(linear, left top, left bottom, from(#fee), to(#fd2))');
        dialog.parents('.ui-dialog').css('background', '-moz-linear-gradient(top, #fee, #fd2)');
        dialog.parents('.ui-dialog').css('filter', 'progid:DXImageTransform.Microsoft.Gradient(Enabled=1,GradientType=0,StartColorStr=#ffeeee,EndColorStr=#ffdd22)');
      }
    } else {
      dialog.parents('.ui-dialog').css('background-color', dialog_bgcolor);
    }
  },

  getType: function(){
    return "Story";
  },

  markIfClosed: function(){
    if(this.$.parents('td').first().hasClass('closed')){
      this.$.addClass('closed');
    } else {
      this.$.removeClass('closed');
    }
  },

  saveDirectives: function(){
    var j = this.$;
    var url;
    var nxt = this.$.next();
    var project = j.parents('tr').find('.story .project .v');
    var view = j.attr('_view');

    var vtype = j.parents('td').first().attr('_rb_type');
    var vid = j.parents('td').first().attr('_rb_sprint_id');

    var data = j.find('.editor').serialize() +
               "&view="+view+
               "&next=" + (nxt.length==1 ? nxt.data('this').getID() : '') +
               (this.isNew() ? "" : "&id=" + j.children('.id').text());

    if (view != "taskboard")
    {
	    var parentId = j.parents('tr').first().attr('_rb_parent_id');
        data += "&parent_issue_id=" + parentId;
	}
    switch (vtype) {
      case 'sprint':
        data += '&release_id=';
        data += '&fixed_version_id='+vid;
        break;
      case 'release':
        data += '&release_id='+vid;
        data += '&fixed_version_id=';
        break;
      case 'productbacklog':
        data += '&release_id=';
        data += '&fixed_version_id=';
        break;
      default:
        break;
    }

    if( this.isNew() ){
      url = RB.urlFor( 'create_story' );
    } else {
      url = RB.urlFor( 'update_story', { id: this.getID() } );
      data += "&_method=put";
    }
    
    return {
      url: url,
      data: data
    };
  },
  
  afterUpdate: function(data, textStatus, xhr){
  	if (RB.Taskboard && RB.permissions.create_tasks) {
      RB.$(this.el).find('.add_new').bind('click', RB.Taskboard.handleAddNewTaskClick);
  	}
  }

});
