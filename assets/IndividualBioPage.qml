import bb.cascades 1.0
import com.canadainc.data 1.0

Page
{
    id: bioPage
    property variant individualId
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    onIndividualIdChanged: {
        helper.fetchBio(bioPage, individualId);
        helper.fetchAllQuotes(bioPage, individualId);
        helper.fetchAllTafsir(bioPage, individualId);
        tafsirHelper.fetchIndividualData(bioPage, individualId);
        tafsirHelper.fetchTeachers(bioPage, individualId);
        tafsirHelper.fetchStudents(bioPage, individualId);
        tafsirHelper.fetchAllWebsites(bioPage, individualId);
    }
    
    function popToRoot()
    {
        while (navigationPane.top != bioPage) {
            navigationPane.pop();
        }
    }
    
    function checkForDuplicate(result)
    {
        var indexPath = bioModel.findExact(result);
        
        if (indexPath.length == 0) {
            bioModel.insert(result);
        }
        
        popToRoot();
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.FetchAllTafsirForSuite && data.length > 0) {
            persist.invoke( "com.canadainc.Quran10.tafsir.previewer", "", "", "quran://tafsir/"+data[0].id.toString() );
        } else if (id == QueryId.FetchIndividualData && data.length > 0) {
            var metadata = data[0];
            
            var result = "";
            
            if (metadata.prefix) {
                result += metadata.prefix+" ";
            }
            
            result += metadata.name;
            
            if (metadata.displayName) {
                titleBar.title = metadata.displayName;
            } else {
                titleBar.title = metadata.name;
            }
            
            if (metadata.kunya) {
                result += " (%1)".arg(metadata.kunya);
            }
            
            result += " ";
            
            if (metadata.birth && metadata.death) {
                result += qsTr("(%1-%2 AH)").arg(metadata.birth).arg(metadata.death);
            } else if (metadata.birth) {
                result += qsTr("(born %1 AH)").arg(metadata.birth);
            } else if (metadata.death) {
                result += qsTr("(died %1 AH)").arg(metadata.death);
            }
            
            result += "\n";

            body.text = "\n"+result;
            ft.play();
        } else if (id == QueryId.RemoveBio) {
            persist.showToast( qsTr("Biography successfully removed!"), "asset:///images/menu/ic_remove_bio.png" );
        } else if (id == QueryId.EditBio) {
            persist.showToast( qsTr("Biography successfully updated!"), "asset:///images/menu/ic_edit_bio.png" );
        } else if (id == QueryId.RemoveTeacher) {
            persist.showToast( qsTr("Teacher removed!"), "asset:///images/menu/ic_edit_bio.png" );
        } else if (id == QueryId.RemoveStudent) {
            persist.showToast( qsTr("Student removed!"), "asset:///images/menu/ic_edit_bio.png" );
        } else if (id == QueryId.AddTeacher) {
            persist.showToast( qsTr("Teacher added!"), "asset:///images/menu/ic_edit_bio.png" );
        } else if (id == QueryId.AddStudent) {
            persist.showToast( qsTr("Student added!"), "asset:///images/menu/ic_edit_bio.png" );
        }
        
        offloader.fillType(data, id, bioModel);
    }
    
    titleBar: TitleBar {}
    
    Container
    {
        layout: DockLayout {}
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        background: bg.imagePaint
        
        Container
        {
            background: Color.Black
            opacity: 0
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            
            animations: [
                FadeTransition {
                    id: ft
                    fromOpacity: 0
                    toOpacity: 0.5
                    easingCurve: StockCurve.SineOut
                    duration: 2000
                }
            ]
        }
        
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            
            TextArea
            {
                id: body
                editable: false
                backgroundVisible: false
                content.flags: TextContentFlag.ActiveText | TextContentFlag.EmoticonsOff
                input.flags: TextInputFlag.SpellCheckOff
                topPadding: 0;
                textStyle.fontSize: FontSize.Large
                bottomPadding: 0; bottomMargin: 0
                horizontalAlignment: HorizontalAlignment.Fill
                textStyle.textAlign: TextAlign.Center
                textStyle.fontWeight: FontWeight.Bold
                textStyle.fontStyle: FontStyle.Italic
                visible: text.length > 0
                
                layoutProperties: StackLayoutProperties {
                    spaceQuota: -1
                }
            }
            
            ImageView {
                topMargin: 0; bottomMargin: 0
                imageSource: "images/dividers/divider_bio_page.png"
                horizontalAlignment: HorizontalAlignment.Center
                visible: itemRoot.ListItem.indexInSection < itemRoot.ListItem.sectionSize-1
            }
            
            ListView
            {
                id: bios
                property variant editIndexPath
                
                layout: StackListLayout {
                    headerMode: ListHeaderMode.Sticky
                }
                
                dataModel: GroupDataModel
                {
                    id: bioModel
                    sortingKeys: ["type"]
                    grouping: ItemGrouping.ByFullValue
                }
                
                function getHeaderName(ListItemData)
                {
                    if (ListItemData == "bio" || ListItemData == "expanded_bio") {
                        return qsTr("Biographies");
                    } else if (ListItemData == "tafsir") {
                        return qsTr("Works");
                    } else if (ListItemData == "teacher") {
                        return qsTr("Teachers");
                    } else if (ListItemData == "student") {
                        return qsTr("Students");
                    } else if (ListItemData == "website") {
                        return qsTr("Websites");
                    } else  {
                        return qsTr("Quotes");
                    }
                }
                
                function itemType(data, indexPath)
                {
                    if (indexPath.length == 1) {
                        return "header";
                    } else {
                        return data.type;
                    }
                }
                
                function onBioSaved(data)
                {
                    tafsirHelper.editBio(bioPage, data.id, data.body, data.reference, data.author_id, data.points);
                    bioModel.updateItem(editIndexPath, data);
                    
                    popToRoot();
                }
                
                function editBio(ListItem)
                {
                    editIndexPath = ListItem.indexPath;
                    definition.source = "CreateBioPage.qml";
                    var page = definition.createObject();
                    page.createBio.connect(onBioSaved);
                    page.data = ListItem.data;
                    
                    navigationPane.push(page);
                }
                
                function removeBio(ListItem)
                {
                    tafsirHelper.removeBio(bioPage, ListItem.data.id);
                    bioModel.removeAt(ListItem.indexPath);
                }
                
                function removeStudent(ListItem)
                {
                    tafsirHelper.removeStudent(bioPage, individualId, ListItem.data.id);
                    bioModel.removeAt(ListItem.indexPath);
                }
                
                function removeTeacher(ListItem)
                {
                    tafsirHelper.removeTeacher(bioPage, individualId, ListItem.data.id);
                    bioModel.removeAt(ListItem.indexPath);
                }
                
                listItemComponents: [
                    ListItemComponent
                    {
                        type: "header"
                        
                        Header
                        {
                            id: header
                            title: header.ListItem.view.getHeaderName(ListItemData)
                            subtitle: header.ListItem.view.dataModel.childCount(header.ListItem.indexPath)
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "bio"
                        
                        StandardListItem
                        {
                            id: sli
                            description: ListItemData.body.replace(/\n/g, " ").substr(0, 60) + "..."
                            imageSource: ListItemData.points > 0 ? "images/list/ic_like.png" : ListItemData.points == 0 ? "images/list/ic_bio.png" : "images/list/ic_dislike.png"
                            title: ListItemData.author ? ListItemData.author : ListItemData.reference ? ListItemData.reference : ""
                            
                            contextMenuHandler: [
                                ContextMenuHandler {
                                    onPopulating: {
                                        if (!reporter.isAdmin) {
                                            event.abort();
                                        }
                                    }
                                }
                            ]
                            
                            contextActions: [
                                ActionSet
                                {
                                    title: sli.title
                                    subtitle: sli.description
                                    
                                    ActionItem
                                    {
                                        imageSource: "images/menu/ic_edit_bio.png"
                                        title: qsTr("Edit") + Retranslate.onLanguageChanged
                                        
                                        onTriggered: {
                                            console.log("UserEvent: EditBio");
                                            sli.ListItem.view.editBio(sli.ListItem);
                                        }
                                    }
                                    
                                    DeleteActionItem
                                    {
                                        imageSource: "images/menu/ic_remove_bio.png"
                                        
                                        onTriggered: {
                                            console.log("UserEvent: RemoveBio");
                                            sli.ListItem.view.removeBio(sli.ListItem);
                                        }
                                    }
                                }
                            ]
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "expanded_bio"
                        
                        Container
                        {
                            id: bioContainer
                            horizontalAlignment: HorizontalAlignment.Fill
                            verticalAlignment: VerticalAlignment.Fill
                            
                            StandardListItem
                            {
                                description: ListItemData.body.replace(/\n/g, " ").substr(0, 60) + "..."
                                imageSource: ListItemData.points > 0 ? "images/list/ic_like.png" : ListItemData.points == 0 ? "images/list/ic_bio.png" : "images/list/ic_dislike.png"
                                title: ListItemData.author ? ListItemData.author : ListItemData.reference ? ListItemData.reference : ""
                            }
                            
                            TextArea
                            {
                                editable: false
                                backgroundVisible: false
                                content.flags: TextContentFlag.ActiveText | TextContentFlag.EmoticonsOff
                                input.flags: TextInputFlag.SpellCheckOff
                                text: qsTr("%1\n%2").arg(ListItemData.body).arg(ListItemData.reference ? ListItemData.reference : "") + Retranslate.onLanguageChanged
                                horizontalAlignment: HorizontalAlignment.Fill
                                textStyle.textAlign: TextAlign.Center
                            }
                            
                            ImageView {
                                topMargin: 0; bottomMargin: 0
                                imageSource: "images/dividers/divider_bio.png"
                                horizontalAlignment: HorizontalAlignment.Center
                                visible: itemRoot.ListItem.indexInSection < itemRoot.ListItem.sectionSize-1
                            }
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "quote"
                        
                        TextArea {
                            backgroundVisible: false
                            editable: false
                            input.flags: TextInputFlag.SpellCheckOff
                            content.flags: TextContentFlag.ActiveTextOff | TextContentFlag.EmoticonsOff
                            text: qsTr("“%1” (%2)").arg(ListItemData.body).arg(ListItemData.reference) + Retranslate.onLanguageChanged
                            horizontalAlignment: HorizontalAlignment.Fill
                            textStyle.textAlign: TextAlign.Center
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "tafsir"
                        
                        StandardListItem
                        {
                            description: ListItemData.author
                            imageSource: "images/list/ic_rijaal_quote.png"
                            title: ListItemData.title
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "teacher"
                        
                        StandardListItem
                        {
                            id: teacherSli
                            imageSource: "images/list/ic_teacher.png"
                            title: ListItemData.teacher
                            
                            contextMenuHandler: [
                                ContextMenuHandler {
                                    onPopulating: {
                                        if (!reporter.isAdmin) {
                                            event.abort();
                                        }
                                    }
                                }
                            ]
                            
                            contextActions: [
                                ActionSet
                                {
                                    title: teacherSli.title
                                    
                                    DeleteActionItem
                                    {
                                        imageSource: "images/menu/ic_remove_teacher.png"
                                        
                                        onTriggered: {
                                            console.log("UserEvent: RemoveTeacher");
                                            teacherSli.ListItem.view.removeTeacher(teacherSli.ListItem);
                                        }
                                    }
                                }
                            ]
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "student"
                        
                        StandardListItem
                        {
                            id: studentSli
                            imageSource: "images/list/ic_student.png"
                            title: ListItemData.student
                            
                            contextMenuHandler: [
                                ContextMenuHandler {
                                    onPopulating: {
                                        if (!reporter.isAdmin) {
                                            event.abort();
                                        }
                                    }
                                }
                            ]
                            
                            contextActions: [
                                ActionSet
                                {
                                    title: studentSli.title
                                    
                                    DeleteActionItem
                                    {
                                        imageSource: "images/menu/ic_remove_student.png"
                                        
                                        onTriggered: {
                                            console.log("UserEvent: RemoveStudent");
                                            studentSli.ListItem.view.removeStudent(studentSli.ListItem);
                                        }
                                    }
                                }
                            ]
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "website"
                        
                        StandardListItem
                        {
                            imageSource: ListItemData.imageSource
                            title: ListItemData.uri
                        }
                    }
                ]
                
                onTriggered: {
                    if (indexPath.length == 1) {
                        console.log("UserEvent: HeaderTapped");
                        return;
                    }
                    
                    var d = dataModel.data(indexPath);
                    console.log("UserEvent: AttributeTapped", d.type);
                    
                    if (d.type == "student" || d.type == "teacher") {
                        persist.invoke( "com.canadainc.Quran10.bio.previewer", "", "", "", d.id.toString() );
                    } else if (d.type == "bio") {
                        d.type = "expanded_bio";
                        bioModel.updateItem(indexPath, d);
                    } else if (d.type == "expanded_bio") {
                        d.type = "bio";
                        bioModel.updateItem(indexPath, d);
                    } else if (d.type == "tafsir") {
                        console.log("UserEvent: InvokeTafsir");
                        helper.fetchAllTafsirForSuite(bioPage, d.id);
                    } else if (d.type == "website") {
                        persist.donate(d.uri);
                    }
                }
                
                layoutProperties: StackLayoutProperties {
                    spaceQuota: 1
                }
            }
        }
    }
    
    attachedObjects: [
        ImagePaintDefinition
        {
            id: bg
            imageSource: "images/backgrounds/background_ayat_page.jpg"
        },
        
        ComponentDefinition {
            id: definition
        },
        
        ActionItem
        {
            id: addStudent
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            imageSource: "images/menu/ic_add_student.png"
            title: qsTr("Add Student") + Retranslate.onLanguageChanged
            
            function onPicked(student, name)
            {
                tafsirHelper.addStudent(bioPage, individualId, student);
                checkForDuplicate( {'id': student, 'student': name, 'type': "student"} );
            }
            
            onTriggered: {
                console.log("UserEvent: AddStudent");
                definition.source = "IndividualPickerPage.qml";
                
                var p = definition.createObject();
                p.picked.connect(onPicked);
                
                navigationPane.push(p);
            }
        },
        
        ActionItem
        {
            id: addTeacher
            ActionBar.placement: ActionBarPlacement.OnBar
            imageSource: "images/menu/ic_add_teacher.png"
            title: qsTr("Add Teacher") + Retranslate.onLanguageChanged
            
            function onPicked(teacher, name)
            {
                tafsirHelper.addTeacher(bioPage, individualId, teacher);
                checkForDuplicate( {'id': teacher, 'teacher': name, 'type': "teacher"} );
            }
            
            onTriggered: {
                console.log("UserEvent: AddTeacher");
                definition.source = "IndividualPickerPage.qml";
                
                var p = definition.createObject();
                p.picked.connect(onPicked);
                
                navigationPane.push(p);
            }
        }
    ]
    
    onCreationCompleted: {
        if (reporter.isAdmin) {
            addAction(addTeacher);
            addAction(addStudent);
        }
        
        helper.textualChange.connect( function() {
            bioModel.clear();
            individualIdChanged();
        });
    }
}