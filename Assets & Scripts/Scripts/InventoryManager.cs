using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class InventoryManager : MonoBehaviour
{
    public static InventoryManager getInstance;

    private GameObject inputFieldSlot;
    private InputField inputField;


    void Awake() {
        getInstance = this;

        inputFieldSlot = GameObject.Find("Chat/InputField");
        inputField = inputFieldSlot.GetComponent<InputField>();
    }

    public GameObject obj;
    [SerializeField] GameObject itemPrefab;
    [SerializeField] Transform spawnLocation, head, legs, feet, chest, lhand, rhand;
    [SerializeField] GridLayoutGroup layout;

    [HideInInspector] public bool isOpen = false;
    List<InventoryItemObject> inventory = new List<InventoryItemObject>();
    
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.I) && !inputField.isFocused)
            UpdateUI();
    }

    void UpdateUI()
    {
        isOpen = !isOpen;

        if (!isOpen)
            obj.SetActive(false);
        else
        {
            obj.SetActive(true);
            SetUp(_Player.local.inventory);
        }

    }

    public void SetUp(Inventory inventory)
    {
        if (!isOpen)
            return;

        Debug.Log("Setting inventory: " + inventory.Count);
        //layout.enabled = true;
        foreach (var item in this.inventory)
            Destroy(item.gameObject);

        this.inventory.Clear();

        foreach (var item in inventory)
        {
            Transform t = null;
            if (item.Slot == ItemSlot.Head)
            {
                t = head;
                GameObject.Find("MyLocalPlayer/ModelHolder/Skin_1/warrior/Helmet/Helmet 1").gameObject.GetComponent<SkinnedMeshRenderer>().enabled = true;
            }            
            else if (item.Slot == ItemSlot.Chest)
                t = chest;
            else if (item.Slot == ItemSlot.Legs)
                t = legs;
            else if (item.Slot == ItemSlot.Feet)
                t = feet;
            else if (item.Slot == ItemSlot.LHand)
                t = lhand;
            else if (item.Slot == ItemSlot.RHand)
                t = rhand;
            else
                t = spawnLocation; 

            GameObject go = Instantiate(itemPrefab, t);

            InventoryItemObject obj = go.GetComponent<InventoryItemObject>();
            if (t != spawnLocation)
                obj.GetComponent<RectTransform>().sizeDelta = new Vector2(51, 51);

            obj.Init(item, t != spawnLocation);
            this.inventory.Add(obj);
           // layout.enabled = false;
        }
    }
}