using UnityEngine;

[CreateAssetMenu(fileName = "Item", menuName = "Custom/Item", order = 1)]
public class Item : ScriptableObject
{
    public int ID;
    public string Name;
    public string Description;
    public Sprite itemSprite;
    public ItemSlot wearableSlot;
    public GameObject droppedPrefab;
}