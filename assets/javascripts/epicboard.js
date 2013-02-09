/***************************************
  EPICBOARD
***************************************/

RB.Epicboard = RB.Object.create(RB.Model, {
    
  initialize: function(el){
    console.log('RB.Epicboard::initialize()');
    var j = RB.$(el);
    var self = this; // So we can bind the event handlers to this object
    
    self.$ = j;
    self.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', self);

    // Initialize column widths
    self.colWidthUnit = RB.$(".swimlane").width();
    self.defaultColWidth = 2;
    self.loadColWidthPreference();
    self.updateColWidths();
    RB.$("#col_width input").bind('keyup', function(e){ if(e.which==13) self.updateColWidths(); });

    // Initialize epic lists, restricting drop to the story
    var epics_lists =j.find('.story-swimlane');

    var sortableOpts = {
      placeholder: 'placeholder',
      distance: 3,
      helper: 'clone', //workaround firefox15+ bug where drag-stop triggers click
      start: self.dragStart,
      stop: self.dragStop,
      update: self.dragComplete
    };

    epics_lists.each(function(index){
      var id = '#' + RB.$(this).attr('id') + ' .list';

      j.find(id).sortable(RB.$.extend({
        connectWith: id
        }, sortableOpts));
    });
    // Initialize unassigned stories list
    j.find("#unassigned_stories .list").sortable(RB.$.extend({
      connectWith: '#unassigned_stories .list'
    }, sortableOpts));

    // Initialize each story in the board
    j.find('.story').each(function(index){
      RB.Factory.initialize(RB.Story, this); // 'this' refers to an element with class="story"
      RB.$(this).addClass('editable');
      RB.$(this).addClass('issue');
    });

    // Add handler for .add_new click
    j.find('#epics .add_new').bind('click', self.handleAddNewEpicClick);

  },
  
  dragComplete: function(event, ui) {
    var isDropTarget = (ui.sender==null); // Handler is triggered for source and target. Thus the need to check.

    if(isDropTarget){
      ui.item.data('this').saveDragResult();
    }    
  },
  
  dragStart: function(event, ui){ 
    if (jQuery.support.noCloneEvent){
      ui.item.addClass("dragging");
    } else {
      // for IE
      ui.item.addClass("dragging");      
      ui.item.draggable('enabled');
    }
  },
  
  dragStop: function(event, ui){ 
    if (jQuery.support.noCloneEvent){
      ui.item.removeClass("dragging");
    } else {
      // for IE
      ui.item.draggable('disable');
      ui.item.removeClass("dragging");      
    }
  },

  handleAddNewEpicClick: function(event){
    if (event.button > 1) return;
    var row = RB.$(this).parents("tr").first();
    RB.$('#epicboard').data('this').newEpic(row);
  },

  loadColWidthPreference: function(){
    var w = RB.UserPreferences.get('epicboardColWidth');
    if(w==null){
      w = this.defaultColWidth;
      RB.UserPreferences.set('epicboardColWidth', w);
    }
    RB.$("#col_width input").val(w);
  },

  newEpic: function(row){
    var epic = RB.$('#epic_template').children().first().clone();
    row.find(".list").first().prepend(epic);
    var o = RB.Factory.initialize(RB.Epic, epic);
    o.edit();
  },
  
  updateColWidths: function(){
    var w = parseInt(RB.$("#col_width input").val(), 10);
    if(w==null || isNaN(w)){
      w = this.defaultColWidth;
    }
    RB.$("#col_width input").val(w);
    RB.UserPreferences.set('epicboardColWidth', w);
    RB.$(".swimlane").width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
  }
});

RB.UserFilter = RB.Object.create({
  initialize: function() {
    var me = this,
      _ = RB.constants.locale._;
    me.el = RB.$(".userfilter");
    me.el.multiselect({
      selectedText: _("Filter epics"),
      noneSelectedText: _("Filter epics: my epics"),
      checkAllText: _("All epics"),
      uncheckAllText: _("My epics"),
      checkAll: function() { me.updateUI(); },
      uncheckAll: function() { me.onUnCheckAll(); },
      click: function() { me.updateUI(); }
    });
    me.el.multiselect('checkAll');
  },

  /* uncheck all users but check the current user, so we get a private mode button */
  onUnCheckAll: function() {
    var uid = RB.$("#userid").text();
    this.el.multiselect("widget").find(":checkbox[value='"+uid+"']").each(function() {this.checked = true;} );
    this.updateUI();
  },

  updateUI: function() {
    this.updateEpics();
    this.updateStories();
  },

  updateEpics: function() {
    var me = this;
    RB.$(".epic").each(function() {
      var epic_ownerid = null;
      try{
        epic_ownerid = RB.$(".assigned_to_id .v", this).text();
      } catch(e){ return; }
      if (!epic_ownerid || me.el.multiselect("widget").find(":checkbox[value='"+epic_ownerid+"']").is(':checked')) {
        RB.$(this).show();
      }else {
        RB.$(this).hide();
      }
    });
  },

  updateStories: function() {
    //Check if all stories should be visible even if not used
    var showUnusedStories = this.el.multiselect("widget").find(":checkbox[value='s']").is(':checked');

    //Parse through all the stories and hide the ones not used
    RB.$('.story').each(function() {
      console.log('Epicboard::updateStories parsing story', this);
      var sprintInfo = RB.$(this).children('.id').children('a')[0];
      var storyID = sprintInfo.innerHTML;

      RB.$(this).closest('tr').show();
      var hasVisEpics = 0;
      var hasEpics = 0;  // Keep track if a story has epics (visible or not)

      //Parse each epic in the story and see if any epics are not hidden
      RB.$("#epics [id^="+storyID+"_]").each(function(){
        RB.$(this).children().each(function(){
          hasEpics = 1;
          if (RB.$(this).is(':visible'))
            hasVisEpics = 1;
        });
      });

      //Hide or show story row based on if any epics are visible
      if (hasVisEpics || (showUnusedStories && !hasEpics))
        RB.$(this).closest('tr').show();
      else
        RB.$(this).closest('tr').hide();
    });
   }
});

RB.$(function(){ /*document ready*/
  RB.$("#board_header").verticalFix({
    delay: 50
  });
  RB.UserFilter.initialize();
});

