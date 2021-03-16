using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class InventoryItemObject : MonoBehaviour, IPointerClickHandler //IDragHandler, IDropHandler, IPointerUpHandler
{
    public InventoryItem item { get; private set; }
    Item _item;
    Vector3 initialPosition;
    bool isWorn;

    [SerializeField] Image img;
    [SerializeField] Button btn;

    public void Init(InventoryItem item, bool isWorn)
    {
        this.item = item;
        this.isWorn = isWorn;

        initialPosition = transform.position;
        _item = ItemDatabase.getInstance.getItem(item.Item);
        img.sprite = _item.itemSprite;
        btn.onClick.AddListener(delegate
        {
            if (item.Slot == ItemSlot.None)
                _Player.local.CmdEquipItem(item.Item);
            else
                _Player.local.CmdUnequipItem(item.Slot);
        });
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if (eventData.button == PointerEventData.InputButton.Right)
            _Player.local.CmdDropItem(item.Item);
    }

    /*
    public void OnDrag(PointerEventData eventData)
    {
        if (isWorn)
            return;

        transform.position = Input.mousePosition;
    }
    public void OnDrop(PointerEventData eventData)
    {
        if (isWorn)
            return;

        RectTransform invPanel = InventoryManager.getInstance.obj.transform as RectTransform;

        if (!RectTransformUtility.RectangleContainsScreenPoint(invPanel, Input.mousePosition))
            _Player.local.CmdDropItem(item.Item);
    }
    void IPointerUpHandler.OnPointerUp(PointerEventData eventData)
    {
        if (isWorn)
            return;

        transform.position = initialPosition;
    }*/
}