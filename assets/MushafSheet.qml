import QtQuick 1.0
import bb.cascades 1.0
import bb.system 1.0
import com.canadainc.data 1.0

Sheet
{
    id: sheet
    
    Page
    {
        id: mainPage
        actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
        actionBarVisibility: ChromeVisibility.Hidden
        
        paneProperties: NavigationPaneProperties {
            backButton: ActionItem {
                title: qsTr("Back") + Retranslate.onLanguageChanged
            }
        }
        
        actions: [
            ActionItem {
                title: qsTr("Jump") + Retranslate.onLanguageChanged
                ActionBar.placement: ActionBarPlacement.OnBar
                imageSource: "images/ic_jump.png"
                
                onTriggered: {
                    hiddenTitle.visibility = ChromeVisibility.Hidden;
                    dropDownDelegate.delegateActive = true;
                    timer.stop();
                }
            }
        ]
        
        titleBar: TitleBar
        {
            id: hiddenTitle
            visibility: ChromeVisibility.Hidden
            title: qsTr("Page %1").arg(scroller.firstVisibleItem[0]+1)
            
            dismissAction: ActionItem
            {
                
                title: qsTr("Back") + Retranslate.onLanguageChanged
                
                onTriggered: {
                    sheet.close();
                }
            }
            
            acceptAction: ActionItem
            {
                title: listView.mushafLock ? qsTr("Unlock") + Retranslate.onLanguageChanged : qsTr("Lock") + Retranslate.onLanguageChanged
                imageSource: listView.mushafLock ? "images/mushaf/ic_unlock.png" : "images/mushaf/ic_lock.png"
                
                onTriggered: {
                    listView.mushafLock = !listView.mushafLock;
                    persist.saveValueFor("mushafLock", listView.mushafLock ? 1 : 0);
                    adm.clear();
                    loadMushaf();
                }
            }
            
            attachedObjects: [
                Timer {
                    id: timer
                    repeat: false
                    interval: 3000
                    
                    onTriggered: {
                        hiddenTitle.visibility = ChromeVisibility.Hidden
                        mainPage.actionBarVisibility = ChromeVisibility.Hidden
                        dropDownDelegate.delegateActive = false;
                    }
                }
            ]
        }
        
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            
            ControlDelegate
            {
                id: progressDelegate
                delegateActive: !mushaf.mushafReady
                horizontalAlignment: HorizontalAlignment.Fill
                
                sourceComponent: ComponentDefinition
                {
                    ProgressIndicator {
                        horizontalAlignment: HorizontalAlignment.Fill
                        fromValue: 0
                        toValue: 614
                        value: mushaf.queued
                    }
                }
            }
            
            ControlDelegate
            {
                id: dropDownDelegate
                horizontalAlignment: HorizontalAlignment.Fill
                delegateActive: false
                
                sourceComponent: ComponentDefinition
                {
                    DropDown
                    {
                        id: dropDown
                        horizontalAlignment: HorizontalAlignment.Fill
                        title: qsTr("Surah")
                        
                        onSelectedValueChanged: {
                            listView.scrollToItem([selectedValue-1], ScrollAnimation.Default);
                        }
                        
                        function onDataLoaded(id, data)
                        {
                            if (id == QueryId.FetchPageNumbers && data.length > 0)
                            {
                                var n = data.length;
                                
                                for (var i = 0; i < n; i++) {
                                    var option = optionDefinition.createObject();
                                    option.text = data[i].arabic_name;
                                    option.description = data[i].english_name;
                                    option.value = data[i].page_number;
                                    dropDownDelegate.control.add(option);
                                }
                                
                                dropDownDelegate.control.expanded = true;
                            }
                        }
                        
                        onCreationCompleted: {
                            helper.fetchPageNumbers(dropDown);
                        }
                    }
                }
                
                attachedObjects: [
                    ComponentDefinition
                    {
                        id: optionDefinition
                        Option {}
                    }
                ]
            }
            
            ListView
            {
                id: listView
                property bool mushafLock: persist.getValueFor("mushafLock") == 1
                
                dataModel: ArrayDataModel {
                    id: adm
                }
                
                onTouch: {
                    hiddenTitle.visibility = ChromeVisibility.Overlay;
                    mainPage.actionBarVisibility = ChromeVisibility.Overlay;
                    timer.restart();
                }
                
                function itemType(data, indexPath) {
                    return mushafLock ? "scaled" : "original"
                }
                
                layout: StackListLayout {
                    orientation: LayoutOrientation.RightToLeft
                }
                
                listItemComponents: [
                    ListItemComponent
                    {
                        type: "scaled"
                        
                        MushafPage {
                            scrollViewProperties.initialScalingMethod: ScalingMethod.AspectFit
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "original"
                        
                        MushafPage {
                            scrollViewProperties.initialScalingMethod: ScalingMethod.None
                        }
                    }
                ]
                
                function onMushafPageReady(imageSource) {
                    adm.append(imageSource);
                }
                
                onCreationCompleted: {
                    mushaf.mushafPageReady.connect(onMushafPageReady);
                }
                
                attachedObjects: [
                    ListScrollStateHandler {
                        id: scroller
                    }
                ]
            }
            
            attachedObjects: [
                SystemDialog {
                    id: prompt
                    title: qsTr("Confirmation") + Retranslate.onLanguageChanged
                    body: qsTr("We are about to download the mushaf (which is about ~200MB in size), you should only attempt to do this if you have either an unlimited data plan, or are connected via Wi-Fi. Otherwise you might incur a lot of data charges. Are you sure you want to continue? If you select No you can always attempt to download again later.") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
                    
                    onFinished: {
                        if (result == SystemUiResult.ConfirmButtonSelection) {
                            mushaf.downloadMushaf();
                            
                            var abort = abortDownloadAction.createObject();
                            mainPage.addAction(abort, ActionBarPlacement.Default);
                        } else {
                            if ( adm.isEmpty() ) {
                                sheet.close();   
                            }
                            
                            progressDelegate.delegateActive = false;
                        }
                    }
                },
                
                ComponentDefinition
                {
                    id: abortDownloadAction
                    
                    DeleteActionItem {
                        title: qsTr("Abort") + Retranslate.onLanguageChanged
                        imageSource: "images/ic_cancel.png"
                        
                        onTriggered: {
                            mushaf.abort();
                            progressDelegate.delegateActive = false;
                        }
                    }
                }
            ]
        }
    }
    
    function loadMushaf()
    {
        if (mushaf.mushafReady) {
            adm.append( mushaf.getMushafPages() );
        } else if (mushaf.queued == 0) {
            adm.append( mushaf.getDownloadedMushafPages() );
            prompt.show();
        } else {
            adm.append( mushaf.getDownloadedMushafPages() );
            
            var abort = abortDownloadAction.createObject();
            mainPage.addAction(abort, ActionBarPlacement.Default);
            
            listView.scrollToPosition(ScrollPosition.Beginning, ScrollAnimation.Default);
        }
    }
    
    onCreationCompleted: {
        loadMushaf();
    }
    
    onClosed: {
        destroy();
    }
    
    onOpened: {
        if (mushaf.mushafReady) {
            listView.scrollToPosition(ScrollPosition.Beginning, ScrollAnimation.Default);
        }
    }
}