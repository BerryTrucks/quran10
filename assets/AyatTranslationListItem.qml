import bb.cascades 1.0

AyatListItem
{
    id: itemRoot
    property alias secondLine: translationLabel
    
    Label
    {
        id: translationLabel
        text: ListItemData.translation
        multiline: true
        horizontalAlignment: HorizontalAlignment.Fill
        textStyle.color: ListItem.selected || ListItemData.playing ? Color.White : Color.Black
        textStyle.textAlign: TextAlign.Center
        textStyle.fontSize: {
            var translationSize = itemRoot.ListItem.view.translationSize;
            
            if (translationSize == 1) {
                return FontSize.Small;
            } else if (translationSize == 2) {
                return FontSize.Medium;
            } else {
                return FontSize.XXLarge;
            }
        }
    }
}