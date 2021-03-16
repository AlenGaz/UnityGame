using Mirror;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;

public class ItemDatabase : MonoBehaviour
{
    public static ItemDatabase getInstance;
    void Awake() { getInstance = this; }

    [SerializeField] Item[] items;

    public List<DroppedItem> droppedItems = new List<DroppedItem>();
    public List<DroppedItemObject> droppedItemObjects = new List<DroppedItemObject>();

    public Item getItem(int id)
    {
        for (int i = 0; i < items.Length; i++)
        {
            if (items[i].ID == id)
                return items[i];
        }

        return null;
    }

    public void InitDroppedItems()
    {
        droppedItems = NetworkingManager.getInstance.database.LoadDroppedItems();
        foreach (DroppedItem d in droppedItems)
        {
            Item i = getItem(d.item);
            if (i == null)
                continue;
            GameObject go = Instantiate(i.droppedPrefab, d.pos, Quaternion.Euler(d.rot));
            DroppedItemObject obj = go.GetComponent<DroppedItemObject>();
            obj.Init(d);
            NetworkServer.Spawn(go);
            droppedItemObjects.Add(obj);
        }
        Debug.Log("Spawned " + droppedItemObjects.Count + " from " + droppedItems.Count);
    }
    public int DropItem(Item item, Vector3 pos, Vector3 rot)
    {
        if (item == null)
            return -1;

        int id = Random.Range(0, int.MaxValue);
        while (IDExists(id))
            id = Random.Range(0, int.MaxValue);
        DroppedItem i = new DroppedItem();
        i.id = id;
        i.item = item.ID;
        i.pos = pos;
        i.rot = rot;
        NetworkingManager.getInstance.database.DropItem(id, item.ID, pos, rot);

        GameObject go = Instantiate(item.droppedPrefab, i.pos, Quaternion.Euler(i.rot));
        DroppedItemObject obj = go.GetComponent<DroppedItemObject>();
        obj.Init(i);
        droppedItemObjects.Add(obj);
        return id;
    }
    public void PickUpItem(int id)
    {
        foreach (var item in droppedItemObjects)
        {
            if (item.item.id == id)
            {
                PickUpItem(item);
                return;
            }
        }
    }
    public void PickUpItem(DroppedItemObject item)
    {
        DroppedItem temp = item.item;
        if (temp == null)
        {
            Destroy(item.gameObject);
            return;
        }

        foreach (var d in droppedItemObjects)
        {
            if (d.item.id == temp.id)
            {
                droppedItemObjects.Remove(d);
                NetworkServer.Destroy(item.gameObject);
                break;
            }
        }
        foreach (var d in droppedItems)
        {
            if (d.id == temp.id)
            {
                droppedItems.Remove(d);
                break;
            }
        }

        NetworkingManager.getInstance.database.PickUpItem(temp.id);
    }
    bool IDExists(int id)
    {
        for (int i = 0; i < droppedItems.Count; i++)
        {
            if (droppedItems[i].id == id)
                return true;
        }

        return false;
    }
}


[System.Serializable]
public class InventoryItem
{
    public int Item;
    public int Quantity;
    public ItemSlot Slot;
}
[System.Serializable]
public class Inventory : SyncList<InventoryItem> { }
[System.Serializable]
public class DroppedItem
{
    public int id;
    public int item;
    public Vector3 pos;
    public Vector3 rot;
}
public enum ItemSlot
{
    None, Head, Legs, Chest, Feet, LHand, RHand,
}