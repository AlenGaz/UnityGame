using FirstGearGames.Mirror.NetworkAnimators;
using Mirror;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

public class _Player : NetworkBehaviour
{
    // Handles Networked Player core stuff, like movement, pickups etc..
    static _Player _local;

    [SerializeField] protected Cooldown _cooldown;
    public Cooldown Cooldown { get { return _cooldown; } }



    //-------Movement variables--------------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------
    //diagonal direction vectors
    Vector2 dirvectorQ = new Vector2(-1, 1);
    Vector2 dirvectorE = new Vector2(1, 1);
    Vector2 dirvectorZ = new Vector2(-1, -1);
    Vector2 dirvectorC = new Vector2(1, -1);

    //updown direction vectors 
    Vector2 dirvectorA = new Vector2Int(-1, 0); // left
    Vector2 dirvectorW = new Vector2Int(0, 1);  // top
    Vector2 dirvectorD = new Vector2Int(1, 0);  // right
    Vector2 dirvectorS = new Vector2Int(0, -1); // bottom


    [Header("Movement Settings")]
    public bool m_AnimateMovement = true;
    public bool m_RotateTowardsDirection = true;


    protected Vector2Int _currentInput = Vector2Int.zero;
    protected Vector2Int _queuedInput = Vector2Int.zero;
    [SerializeField]
    public GridObject _gridObject;
    [SerializeField]
    protected GridMovement _gridMovement;

    Dictionary<int, float> spellCooldown = new Dictionary<int, float>();
    Dictionary<SpellType, float> coreSpellCooldown = new Dictionary<SpellType, float>();

    float maxHealth;
    [SyncVar(hook = nameof(OnHealthChange))] float currentHealth;
    float maxMana;
    [SyncVar(hook = nameof(OnManaChange))] float currentMana;
    [SerializeField] float expLossOnDeath = 10f;
    [SyncVar(hook = nameof(OnEXPChange))] float exp;
    //[SyncVar(hook = nameof(OnEXPChange))] int profession;
    [SerializeField] public int profession;

    [SerializeField] GameObject floatingTextPrefab;

    //Both per second
    [SerializeField] float healthRegen;
    [SerializeField] float manaRegen;


    [Header("Profession Prefabs")]
    public GameObject knightPrefab;
    public GameObject wizardPrefab;
    public GameObject priestPrefab;
    public GameObject rangerPrefab;
    bool onlyOnce = true;


    protected virtual void Setup()
    {
        _gridObject = GetComponent<GridObject>();
        _gridMovement = GetComponent<GridMovement>();


    }


    //-------Movement variables--------------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------

    public static _Player local
    {
        get
        {
            if (_local == null)
            {
                System.Object[] players = Resources.FindObjectsOfTypeAll(typeof(_Player));
                _Player p = null;
                foreach (var _p in players)
                {
                    if ((_p as _Player).isLocalPlayer)
                    {

                        _local = _p as _Player;
                        break;
                    }
                }
            }
            return _local;
        }
    }

    [SerializeField] Text nameText;

    [HideInInspector] [SyncVar] public int id;
    [HideInInspector] [SyncVar] public CharacterInfo info;
    public NetworkConnection _con;
    public Inventory inventory;

    [HideInInspector] [SyncVar] public Vector3 position = Vector3.zero;
    //[HideInInspector] [SyncVar] public Quaternion rotation = Quaternion.identity;      ////////////////////////////////////////
    [HideInInspector] [SyncVar] public Vector2Int facingDirection = Vector2Int.up;

    [SerializeField] GameObject projectile;
    Vector3 prevPos;
    Quaternion prevRot;

    DroppedItemObject pickup;
    int sp = -1;
    int _spell
    {
        get { return sp; }
        set { sp = value; }
    }

    List<DroppedItemObject> droppedItems = new List<DroppedItemObject>();

    public NetworkConnection con
    {
        get
        {
            if (_con == null && isClient)
                _con = connectionToServer;
            else if (_con == null && isServer)
                _con = connectionToClient;

            return _con;
        }
        set
        {
            _con = value;
        }
    }

    [SyncVar] bool spawned = false;
    private Vector2 direction;

    [SerializeField] float attackSpeed = 1f;
    //MWALL
    public GridObject mwallPrefab;
    public GridObject SdPrefab;
    public GridObject teleportPrefabEffect;
    public GridObject wingsPrefabEffect;
    public GridObject healPrefabEffect;

    Coroutine attackRoutine;

    public void Init(int id, NetworkConnection con, CharacterInfo info)
    {
        this.id = id;
        this.con = con;
        this.info = info;
        maxHealth = info.maxHealth;
        currentHealth = maxHealth;
        maxMana = info.maxMana;
        currentMana = maxMana;
        exp = info.exp;
        profession = info.profession;

        _spell = -1;

        GetComponentInChildren<Slider>().maxValue = info.maxHealth;
        GetComponentInChildren<Slider>().value = currentHealth;

        prevPos = position = transform.position;
        //prevRot = rotation = transform.rotation;
        Debug.Log("Previous Pos" + prevPos);
        Debug.Log("Previous Rot" + prevRot);
        //GetComponentInChildren<UI_non_rotate>().rotation = namePlateRotation;

        Debug.Log("Spawning player with name: " + info.name + " and profession:" + profession);

        try
        {
            nameText.text = info.name;

            Debug.Log(nameText.text);
        }
        catch (System.Exception) { Debug.Log("Except......
	............
		..................

    }




    public CharacterInfo OnDisconnection()
    {
        CharacterInfo c = new CharacterInfo();
        c.id = info.id;
        c.name = info.name;
        c.maxHealth = maxHealth;
        c.maxMana = maxMana;
        c.exp = exp;
        return c;
    }

    public void SendChatMessage(string msg)
    {
        CmdSendChatMessage("[" + info.name + "]: " + msg);
    }

    [Command]
    void CmdSendChatMessage(string msg)
    {
        RpcSendChatMessage(msg);
    }
    [ClientRpc]
    void RpcSendChatMessage(string msg)
    {
        ChatManager.getInstance.GetMessage(msg);
    }

    int lastSpell = -1;

    private void Update()
    {
        if (isServer)
            UpdateCooldowns();

        if (!isLocalPlayer)
            return;

        if (Input.GetKeyDown(KeyCode.F1))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(0);
        }
        else if (Input.GetKeyDown(KeyCode.F2))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(7);
        }
        else if (Input.GetKeyDown(KeyCode.F3))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(2);
        }
        else if (Input.GetKeyDown(KeyCode.F4))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(3);
        }
        else if (Input.GetKeyDown(KeyCode.F5))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(5);
        }
        else if (Input.GetKeyDown(KeyCode.F6))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(6);
        }
        else if (Input.GetKeyDown(KeyCode.F7))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(1);
        }
        else if (Input.GetKeyDown(KeyCode.F8))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(8);
        }
        else if (Input.GetKeyDown(KeyCode.F9))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);
            ClientSetSpell(9);
        }

        else if (Input.GetKeyDown(KeyCode.F11))
        {
            if (attackRoutine != null)
                if (profession != 0) { return; }
                StopCoroutine(attackRoutine);
            ClientSetSpell(10);
        }

        if (Input.GetKeyDown(KeyCode.F11))
        {
            ClientSetSpell(profession);
        }

        if (Input.GetKeyDown(KeyCode.W) || (Input.GetKeyDown(KeyCode.A)) || (Input.GetKeyDown(KeyCode.Keypad4)))
        {
            if (onlyOnce)
            {
                CmdChangePlayersPrefabFromProfession(profession);
            }
            if (UnityEngine.Random.Range(0, 1) > 0.8)
            {
                CmdChangePlayersPrefabFromProfession(profession);
            }
           
        }


        if (Input.GetMouseButtonDown(0))
        {
            if (attackRoutine != null)
                StopCoroutine(attackRoutine);

            GridTile tile = GridManager.Instance.m_HoveredGridTile;
            if (tile != null)
            {
                Debug.Log("Input spell: " + lastSpell);
                CmdSetSpell(lastSpell, tile.m_GridPosition.x, tile.m_GridPosition.y, true);
                lastSpell = -1;
            }
        }
        if (Input.GetMouseButton(1))
        {
            GridTile tile = GridManager.Instance.m_HoveredGridTile;
            GridObject obj = GridManager.Instance.GetGridObjectAtPosition(tile.m_GridPosition);
            if (obj != null)
            {
                if (obj.CompareTag("Player") || obj.CompareTag("AI"))
                {
                    if (attackRoutine != null)
                        StopCoroutine(attackRoutine);

                    attackRoutine = StartCoroutine(attack(obj.gameObject));
                }
                else
                {
                    if (attackRoutine != null)
                        StopCoroutine(attackRoutine);
                }
            }
            else
            {
                if (attackRoutine != null)
                    StopCoroutine(attackRoutine);
            }
        }
    }
    IEnumerator attack(GameObject target)
    {
        if (target == null)
            yield break;

        while (true)
        {
            CmdAttack(target);
            yield return new WaitForSeconds(attackSpeed);
        }
    }
    [Command]
    void CmdAttack(GameObject target)
    {
        GameObject go = Instantiate(projectile, transform.position, transform.rotation);
        go.transform.LookAt(target.transform);
        RpcAttack(target);
        Projectile p = go.GetComponent<Projectile>();
        p.Init(target);
    }
    [ClientRpc]
    void RpcAttack(GameObject target)
    {
        GameObject go = Instantiate(projectile, transform.position, transform.rotation);
        go.transform.LookAt(target.transform);
        Projectile p = go.GetComponent<Projectile>();
        p.Init(target);
    }
    void ClientSetSpell(int spell)
    {
        Spell sp = SpellDatabase.getInstance.getSpell(spell);
        if (sp.aimType == AimSpellType.Aim)
            lastSpell = spell;

        CmdSetSpell(spell, 0, 0, false);
    }
    private void FixedUpdate()
    {

        if (info != null && nameText != null)
            nameText.text = info.name;


        if (!isLocalPlayer)
            return;

        if (!spawned)
            return;

        if (isClient)
        {
            if (transform.position != prevPos || transform.rotation != prevRot)
            {
                position = transform.position;
                //rotation = transform.rotation;              ////////////////////////////////
                prevPos = transform.position;
                prevRot = transform.rotation;
            }
        }

        if (pickup != null && Input.GetKeyDown(KeyCode.O))
            CmdPickUp(pickup.item.id, pickup.item.item);



        if (Input.GetMouseButtonDown(0))
        {

            Plane p = new Plane(Camera.main.transform.forward, transform.position);
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;

            if (Physics.Raycast(ray, out hit, 100))
            {

                //Tag Comparison
                if (hit.collider.gameObject.CompareTag("PickUp") && pickup != null)
                {
                    ///Do Logic
                    Debug.Log("Clicking the pickup object");
                    CmdPickUp(pickup.item.id, pickup.item.item);
                }


            }
        }

        if (hasAuthority) {   // Beginning code of Server-Authorative Movement
            _currentInput = GetMovementInputs();
        
        if (direction != Vector2Int.zero) {
            CmdExecuteMoveInput(direction.ToVector2Int(), netIdentity); }
            }
        else { return; }


        //Debug.Log("GetCompdir" + GetComponent<GridObject>().m_FacingDirection);
        //Debug.Log("facingDiratm" + facingDirection);

        if (GetComponent<GridObject>().m_FacingDirection != facingDirection)
        {
            facingDirection = GetComponent<GridObject>().m_FacingDirection;
            CmdSetFacingDirection(facingDirection);
            //Debug.Log("Changed Facing direction"+ facingDirection);

        }

    }

    private Vector2Int GetMovementInputs()
    {
        // MOVEMENT INPUTS
        direction = Vector2Int.zero;
        // south
        if (Input.GetKey(KeyCode.DownArrow) || (Input.GetKey(KeyCode.S) || (Input.GetKey(KeyCode.Keypad2))))
        {
            direction = dirvectorS;

        }

        // west
        if (Input.GetKey(KeyCode.LeftArrow) || (Input.GetKey(KeyCode.A)) || (Input.GetKey(KeyCode.Keypad4)))
        {
            direction = dirvectorA;

        }

        //east
        if (Input.GetKey(KeyCode.RightArrow) || (Input.GetKey(KeyCode.D)) || (Input.GetKey(KeyCode.Keypad6)))
        {
            direction = dirvectorD;
        }

        //north
        if (Input.GetKey(KeyCode.UpArrow) || (Input.GetKey(KeyCode.W) || (Input.GetKey(KeyCode.Keypad8))))
        {
            direction = dirvectorW;
        }

        // DEFINED Q Z E C TO MOVE DIAGONALLY
        if (Input.GetKeyDown(KeyCode.Q) || Input.GetKeyDown(KeyCode.Keypad7))
        {
            direction = dirvectorQ;
        }

        if (Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.Keypad9))
        {
            direction = dirvectorE;
        }

        if (Input.GetKeyDown(KeyCode.Z) || Input.GetKeyDown(KeyCode.Keypad1))
        {
            direction = dirvectorZ;

        }
        if (Input.GetKeyDown(KeyCode.C) || Input.GetKeyDown(KeyCode.Keypad3))
        {
            direction = dirvectorC;
        }

        return direction.ToVector2Int();
    }

    [Command]
    private void CmdSendMovementDirection(Vector2Int direction)
    {
        NetworkIdentity s_ = GetComponent<NetworkIdentity>();
        Debug.Log("Direction from player" + direction);
        CmdExecuteMoveInput(direction,  s_);
    }

    
    [Command]
    private void CmdExecuteMoveInput(Vector2Int direction, NetworkIdentity sender)
    {

        _gridObject = gameObject.GetComponent<GridObject>();
        _gridMovement = gameObject.GetComponent<GridMovement>();


        Vector2Int actionDirection;
        if (direction != null)
        {

            actionDirection = _currentInput;
        }
        else
        {
            actionDirection = direction;
        }

        // If the direction is null/zero return
        //if (actionDirection == Vector2Int.zero) {
        //print("returning from actionDirection is zero");
        //return;}



        // Try to move to the target position
        var targetPosition = _gridObject.m_GridPosition + actionDirection;
        MovementResult movementResult = _gridMovement.TryMoveToNeighborInPosition(targetPosition, m_AnimateMovement, m_RotateTowardsDirection);


        // Queue the desired input if the movement is currently in cooldown
        if (movementResult == MovementResult.Cooldown)
        {
            _queuedInput = _currentInput;
            return;
        }


        // If movement was succesful or failed for some other reason we remove the current input
        _currentInput = Vector2Int.zero;


        RpcReceiveMovement(targetPosition, sender);
    }

    [Command]
    protected virtual void CmdExecuteQueuedInput()
    {
        // If there is not queued input direction
        if (_queuedInput == Vector2Int.zero)
        {
            return;
        }

        Vector2Int specificAction = _queuedInput;
        //CmdClear_queuedInput();
        CmdExecuteMoveInput(specificAction, netIdentity);
    }


    [Command]
    // Clear the queue
    protected virtual void CmdClear_queuedInput()
    {
        _queuedInput = Vector2Int.zero;
    }

    // Callback for the movement ended on GridMovement, used to execute queued input
    [Command]
    protected virtual void CmdMovementEnded(GridMovement movement, GridTile fromGridPos, GridTile toGridPos)
    {
        CmdExecuteQueuedInput();
    }



    [Command]
    public void CmdMovePlayer()
    {

    }
    


    
    [ClientRpc]
    private void RpcReceiveMovement(Vector2Int direction, NetworkIdentity sender)
    {
        
        //_gridObject = sender.gameObject.GetComponent<GridObject>();
        //_gridMovement = sender.gameObject.GetComponent<GridMovement>();
        //Vector2Int targetGridPosition = targetPos;

        //var targetGridTile = GridManager.Instance.NeighborAtPosition(_gridObject.m_CurrentGridTile, targetGridPosition);
        //Debug.Log(targetGridTile.GetType());
        //var targetPosition = _gridObject.m_GridPosition + targetPos;
        //MovementResult movementResult = _gridMovement.TryMoveToNeighborInPosition(targetPosition, m_AnimateMovement, m_RotateTowardsDirection);
        //_gridMovement.MoveTo(targetGridTile,true, true);
        // Debug.Log("moving " + _gridObject.gameObject.name + " to Gridtile " + targetGridTile);



        _gridObject = gameObject.GetComponent<GridObject>();
        _gridMovement = gameObject.GetComponent<GridMovement>();



        Vector2Int actionDirection;
        if (direction != null)
        {

            actionDirection = _currentInput;
        }
        else
        {
            actionDirection = direction;
        }

        // If the direction is null/zero return
        //if (actionDirection == Vector2Int.zero) {
        //print("returning from actionDirection is zero");
        //return;}

        // Try to move to the target position
        var targetPosition = _gridObject.m_GridPosition + actionDirection;
        MovementResult movementResult = _gridMovement.TryMoveToNeighborInPosition(targetPosition, m_AnimateMovement, m_RotateTowardsDirection);

        // Queue the desired input if the movement is currently in cooldown
        if (movementResult == MovementResult.Cooldown)
        {
            _queuedInput = _currentInput;
            return;
        }


        // If movement was succesful or failed for some other reason we remove the current input
        _currentInput = Vector2Int.zero;


    }  


    private void OnTriggerEnter(Collider other)
    {
        if (other.tag == "PickUp")
            pickup = other.GetComponent<DroppedItemObject>();

    }
    private void OnTriggerExit(Collider other)
    {

        if (other.tag == "PickUp")
        {
            if (pickup = other.GetComponent<DroppedItemObject>())
                pickup = null;
        }
    }

    [Command]
    void CmdPickUp(int id, int itemId)
    {
        ItemDatabase.getInstance.PickUpItem(id);
        AddItem(ItemDatabase.getInstance.getItem(itemId), 1);
        RpcDestroyItem(id);

    }
    [ClientRpc]
    void RpcPickUp(int id)
    {
        foreach (var item in droppedItems)
        {
            if (item.item.id == id)
            {
                droppedItems.Remove(item);
                //Destroy(item.gameObject);

            }
        }

    }
    [ClientRpc]
    void RpcDestroyItem(int id)
    {
        foreach (var item in droppedItems)
        {
            if (item.item.id == id)
            {
                Destroy(item.gameObject);
                droppedItems.Remove(item);
            }
        }
    }

    public void AddItem(Item item, int quantity)
    {
        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].Item == item.ID)
            {
                inventory[i].Quantity += quantity;
                NetworkingManager.getInstance.database.UpdateInventory(info.name, item.ID, inventory[i].Quantity);
                InventoryManager.getInstance.SetUp(inventory);
                return;
            }
        }

        inventory.Add(new InventoryItem { Item = item.ID, Quantity = quantity, Slot = ItemSlot.None });
        NetworkingManager.getInstance.database.AddItemInInventory(info.name, item.ID, quantity);
    }
    public void RemoveItem(Item item, int quantity)
    {
        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].Item == item.ID)
            {
                if (inventory[i].Quantity >= quantity)
                {
                    inventory[i].Quantity -= quantity;
                    bool remove = false;
                    if (inventory[i].Quantity == 0)
                    {
                        remove = true;
                        inventory.RemoveAt(i);
                    }

                    NetworkingManager.getInstance.database.UpdateInventory(info.name, item.ID, remove ? 0 : inventory[i].Quantity);
                    InventoryManager.getInstance.SetUp(inventory);
                    return;
                }
            }
        }
    }
    public void EquipItem(Item item)
    {
        if (item == null)
            return;
        ItemSlot slot = item.wearableSlot;
        if (slot == ItemSlot.None)
            return;
        if (!HasItme(item))
            return;

        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].Slot == slot)
            {
                NetworkingManager.getInstance.database.UpdateInventorySlot(info.name, inventory[i].Item, ItemSlot.None);
                if (inventory[i].Slot == ItemSlot.Head)
                {
                    //GameObject.Find("MyLocalPlayer/ModelHolder/Skin_1/warrior/Helmet/Helmet 1").gameObject.GetComponent<SkinnedMeshRenderer>().enabled = true;
                }
                inventory[i].Slot = ItemSlot.None;
                break;
            }
        }
        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].Item == item.ID)
            {
                inventory[i].Slot = slot;
                NetworkingManager.getInstance.database.UpdateInventorySlot(info.name, item.ID, slot);
                InventoryManager.getInstance.SetUp(inventory);
                break;
            }
        }
    }
    public void UnequipItem(ItemSlot slot)
    {
        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].Slot == slot)
            {
                if (inventory[i].Slot == ItemSlot.Head)
                {
                    GameObject.Find("MyLocalPlayer/ModelHolder/Skin_1/warrior/Helmet/Helmet 1").gameObject.GetComponent<SkinnedMeshRenderer>().enabled = false;
                }
                inventory[i].Slot = ItemSlot.None;
                NetworkingManager.getInstance.database.UpdateInventorySlot(info.name, inventory[i].Item, ItemSlot.None);
                InventoryManager.getInstance.SetUp(inventory);
                break;
            }
        }
    }
    public bool HasItme(Item item)
    {
        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].Item == item.ID)
                return true;
        }
        return false;
    }

    public void SetInventory(List<InventoryItem> inventory)
    {
        this.inventory = new Inventory();
        foreach (var item in inventory)
            this.inventory.Add(item);
    }

    [Command]
    public void CmdEquipItem(int item)
    {
        Debug.Log("Equipping item" + netIdentity);
        EquipItem(ItemDatabase.getInstance.getItem(item));
    }
    [Command]
    public void CmdUnequipItem(ItemSlot slot)
    {
        UnequipItem(slot);
    }
    [Command]
    public void CmdDropItem(int item)
    {
        Debug.Log("CmdDropItem called");
        RemoveItem(ItemDatabase.getInstance.getItem(item), 1);
        int id = ItemDatabase.getInstance.DropItem(ItemDatabase.getInstance.getItem(item), transform.position, transform.eulerAngles);
        RpcDropItem(item, transform.position, transform.rotation, id);
    }
    [ClientRpc]
    void RpcDropItem(int item, Vector3 pos, Quaternion rot, int id)
    {
        Debug.Log("RpcDropItem called");
        DropItem(item, pos, rot, id);
    }
    public void DropItem(int item, Vector3 pos, Quaternion rot, int id)
    {
        GameObject go = Instantiate(ItemDatabase.getInstance.getItem(item).droppedPrefab, pos, rot);
        DroppedItemObject i = go.GetComponent<DroppedItemObject>();
        i.Init(new DroppedItem
        {
            id = id,
            item = item,
            pos = pos,
            rot = rot.eulerAngles
        });
        droppedItems.Add(i);
        Debug.Log(droppedItems[droppedItems.Count - 1] + "dropped Item");
    }

   
    [Command]
    public void CmdSetFacingDirection(Vector2Int facingDir)
    {
       
        facingDirection = facingDir;
    }




    [Command]
    public void CmdSetSpell(int spell, int x, int y, bool cast)
    {
        Spell s = SpellDatabase.getInstance.getSpell(spell);
        if (s == null && !cast)
            return;

        if (!cast)
            Debug.Log("CmdCastSpell, id: " + spell + " aim: " + s.aimType + " cast: " + cast);
        if (!cast)
        {
            if (s.aimType == AimSpellType.Aim)
                _spell = id;
            else
            {
                CastSpell(spell, new Vector2Int(_gridObject.m_GridPosition.x, _gridObject.m_GridPosition.y));
                _spell = -1;
            }
        }
        else
        {
            Debug.Log("Casting spell with id: " + spell);
            if (spell != -1)
                CastSpell(spell, new Vector2Int(x, y));
            _spell = -1;
        }
        return;
    }


    [ClientRpc]
    public void RpcSetSelectedSpell(int spellId)
    {
        _spell = spellId;
    }

    [Command]
    public void CmdTeleportObject(GameObject targetObject, Vector2Int playersPosition, Vector2Int targetPos)
    {
        if (targetObject == null) { Debug.Log("targetObject is null"); }
        if (targetPos == null) { Debug.Log("targetPos is null"); }

        GridTile targetGridTile = GridManager.Instance.GetGridTileAtPosition(targetPos);
        if ((playersPosition.x == targetPos.x || targetPos.y == playersPosition.y) && (Vector2.Distance(playersPosition, targetPos) == 4))
        {
            if (targetObject.GetComponent<GridMovement>().TryMoveTo(targetGridTile, false, false, false) == MovementResult.Moved)
            {
                RpcTeleportObject(targetObject, targetPos);
            }
        }
    }

    [ClientRpc]
    public void RpcTeleportObject(GameObject targetObject, Vector2Int targetPos)
    {
        GridTile targetGridTile = GridManager.Instance.GetGridTileAtPosition(......
	............
		..................

    }




    [Command(ignoreAuthority = true)] //pushing another player 
    public void CmdPushTarget(Vector3 pushersPosition, GameObject targetObject, Vector2Int targetPos)
    {

        Debug.Log("Pushing player" + targetObject.gameObject.name + "to" + targetPos);
        if (targetObject == null) { Debug.Log("targetObject is null"); }
        if (targetPos == null) { Debug.Log("targetPos is null"); }

        GridTile targetGridTile = GridManager.Instance.GetGridTileAtPosition(targetPos);
        if (targetObject.GetComponent<GridMovement>().TryMoveTo(targetGridTile, true, true, true) == MovementResult.Moved)
        {
            if (Mathf.Abs(Vector3.Distance(targetObject.transform.position, pushersPosition)) < Mathf.Abs(2f))
                if (targetPos != targetObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition) // Added to not trigger push when click ..
                {
                    RpcPushTarget(targetObject, targetPos);
                }
        }
    }

    [ClientRpc]
    private void RpcPushTarget(GameObject targetObject, Vector2Int targetPos)
    {
        GridMovement _g;
        _g = targetObject.GetComponent<GridMovement>();

        GridTile targetGridTile = GridManager.Instance.GetGridTileAtPosition(targetPos);
        _g.MoveTo(targetGridTile, true, true);

        if(targetObject== this.gameObject)
        {
            gameObject.GetComponent<GridMovement>().MoveTo(targetGridTile, true, true);
            Debug.Log("Every player should move himself now if its him yo");
            doPushSelf(targetObject, targetPos);
        }
        
    }

    public void doPushSelf(GameObject targetObject, Vector2Int targetPos)
    {
        GridMovement _g;
        _g = targetObject.GetComponent<GridMovement>();

        GridTile targetGridTile = GridManager.Instance.GetGridTileAtPosition(targetPos);
        _g.MoveTo(targetGridTile, true, true);

        if (targetObject == this.gameObject)
        {
            gameObject.GetComponent<GridMovement>().MoveTo(targetGridTile, true, true);
            Debug.Log("in doPushSelf, Player should move himself now");
        }
    }


    [Command (ignoreAuthority = true)]
    public void CmdSpawnObjectInPosition(string obj, Vector2Int gridPosition)
    {
        if (obj == "mWall") { Debug.Log("Received spawn mWall command"); }
        if (obj == "Sd") { Debug.Log("Received spawn Sd command"); }
        if (obj == "Wings") { Debug.Log("Received haste command"); }

        if (obj == "mWall")
        {
            if (!GridManager.......
	............
		..................
 			//check if the position is free first
            {
                RpcSpawnObjectInPosition(obj, gridPosition);
            }
        }
        else { RpcSpawnObjectInPosition(obj, gridPosition); }
    }

    [ClientRpc]
    private void RpcSpawnObjectInPosition(string obj, Vector2Int gridPosition)
    {
        GridObject targetAttack;
        Slider targetAttackSlider;
        float damageValue;

        if (obj == "mWall")
        {
            GridManager.Instance.InstantiateGridObject(mwallPrefab, gridPosition);
        }

        if (obj == "Sd")
        {
            Color greenC = Color.green;
            Color yellowC = Color.yellow;
            Color redC = Color.red;

            targetAttack = GridManager.Instance.GetGridObjectAtPosition(gridPosition);
            damageValue = UnityEngine.Random.Range(0.11f, 0.18f);


            Vector3Int Worldpos = new Vector3Int(0, 0, 1); //offset for effect
            if (targetAttack.CompareTag("Character") || targetAttack.CompareTag("Enemy") && targetAttack.gameObject.name != this.gameObject.name)
            {

                targetAttackSlider = targetAttack.gameObject.GetComponentInChildren<Slider>();
                targetAttack.gameObject.GetComponentInChildren<Slider>().value -= damageValue;

                if (targetAttackSlider.value < 0.35)
                {
                    targetAttackSlider.transform.GetComponentInChildren<HealthBarReactions>().gameObject.GetComponentInChildren<Image>().color = redC;
                }

                if (targetAttackSlider.value < 0.6 && targetAttackSlider.value > 0.35)
                {
                    targetAttackSlider.transform.GetComponentInChildren<HealthBarReactions>().gameObject.GetComponentInChildren<Image>().color = yellowC;
                }

                if (targetAttackSlider.value >= 0.6)
                {
                    targetAttackSlider.transform.GetComponentInChildren<HealthBarReactions>().gameObject.GetComponentInChildren<Image>().color = greenC;

                }
            }

            GridManager.Instance.InstantiateGridAbility(SdPrefab, gridPosition);
        }

        if (obj == "Wings")
        {
            Debug.Log("Got RPC to spawn Wings");
            GridManager.Instance.InstantiateGridAbility(wingsPrefabEffect, gridPosition);
            gameObject.GetComponentInChildren<Slider>().value += 0.15f;
        }
    }

    [Server]
    public bool CanCastSpell(Spell spell)
    {
        if (spellCooldown.ContainsKey(spell.ID))
            return false;

        if (coreSpellCooldown.ContainsKey(spell.type))
            return false;

        return currentMana >= spell.manaNeeded;
    }
    public void CastSpell(int spellId, Vector2Int target)
    {
        Spell spell = SpellDatabase.getInstance.getSpell(spellId);
        if (spell == null)
            return;

        if (!CanCastSpell(spell))
            return;

        currentMana -= spell.manaNeeded;
        currentMana = Mathf.Clamp(currentMana, 0, maxMana);
        spellCooldown.Add(spell.ID, spell.Cooldown);
        coreSpellCooldown.Add(spell.type, spell.type == SpellType.Attack ? 2f : 1f);

        GridTile center = GridManager.Instance.GetGridTileAtPosition(target);

        if (spell.castProjectile)
        {
       		 ......
		............
			..................

            //projectileSpawn.GetComponent<Projectile>().Move();
            //projectileSpawn.GetComponent<CharacterController>().SimpleMove(gameObject.transform.position, center.transform.position + new Vector3(0f, 0.5f, 0f));
            
            Debug.Log("centerTransformposition: ......
		............
		..................


        }


        StartCoroutine(createSpellTiles(spell, target));

    }
    IEnumerator createSpellTiles(Spell spell, Vector2Int target)
    {
        GridTile center = GridManager.Instance.GetGridTileAtPosition(target);
        List<GridTile> spellTiles = new List<GridTile>() { center };
        spellTiles.AddRange(GetSpellTiles(spell, center));

        float damageRng;
        float healRng;
        

        for (int i = 0; i < spellTiles.Count; i++)
        {
            if (spellTiles[i] == null)
                continue;

            Debug.Log("Spell Tile pos: " + spellTiles[i].m_GridPosition);

            RpcSpawnSpellTile(new Vector3(spellTiles[i].m_GridPosition.x, spellTiles[i].m_GridPosition.y, 0), spell.ID);
            Vector2Int p = spellTiles[i].m_GridPosition;
            if (p != _gridObject.m_CurrentGridTile.m_GridPosition)
            {
                GridObject o = GridManager.Instance
		......
		............
		..................

            }

            /* 
             * Doesnt work cause need to figure out how to translate gridposition to unity worldposition
             * float px = p.x;
             float py = 0.5f;
             float pz = p.y;
             Vector3 pVec = new Vector3(px, py, pz);
             Debug.Log("pVec is:" + pVec);
             //GameObject Z = Instantiate(spell.prefab.gameObject, pVec, Quaternion.identity);
            //RpcSpawnSpellTile(spellTiles[i].m_WorldPosition, spell.ID); also didnt work but closer
             */



            yield return null;
            GridObject obj = GridManager.Instance.GetGridObjectAtPosition(spellTiles[i].m_GridPosition);
            if (obj != null)
            {
                if (obj.CompareTag("Character"))
                {
                    _Player player = obj.transform.root.GetComponent<_Player>();
                    if (player == null)
                        continue;

                    if (player.id == id && !spell.dealDamage && spell.type != SpellType.Support)
                        continue;

                    if (player.id != id && spell.dealDamage || spell.type == SpellType.Attack || player.gameObject != this.gameObject)
                    {
                        damageRng = (UnityEngine.Random.Range(0, spell.rngRange)) + spell.value;
                        damageRng = Mathf.Floor(damageRng);

                        player.TakeDamage(damageRng);
                        Debug.Log("Taking Damage:" + damageRng + "player:" + player.name);
                    }
                    else
                    {
                        healRng = (UnityEngine.Random.Range(0, spell.rngRange)) + spell.value;
                        healRng = Mathf.Floor(healRng);
                        player.HealHealth(healRng);
                    }
                }
                else if (obj.CompareTag("AI"))
                {
                    AI ai = obj.transform.root.GetComponent<AI>();
                    if (ai == null)
                        continue;

                    if (ai.id == id && !spell.dealDamage && spell.type != SpellType.Support)
                        continue;

                    if (ai.id != id && spell.dealDamage || spell.type == SpellType.Attack || ai.gameObject != this.gameObject)
                    {
                        damageRng = (UnityEngine.Random.Range(0, spell.rngRange)) + spell.value;
                        damageRng = Mathf.Floor(damageRng);

                        ai.TakeDamage(damageRng, this);
                        Debug.Log("Taking Damage:" + damageRng + "player:" + ai.name);
                    }
                }
            }
        }
    }
    [ClientRpc]
    void RpcSpawnSpellTile(Vector3 pos, int spellId)
    {
        if (isServer)
            return;

        Spell spell = SpellDatabase.getInstance.getSpell(spellId);
        Vector2Int p = new Vector2Int((int)pos.x, (int)pos.y);
        if (p != GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition)
        {
            GridObject o = GridManager.Instance.InstantiateGridAbility(spell.prefab == null ? SdPrefab : spell.prefab, p);
            o.GetComponent<GridObject>().enabled = false;

            Destroy(o.gameObject, spell.prefabDestroyTime);
        }

    }


    List<GridTile> GetSpellTiles(Spell spell, GridTile middleTile)
    {
        List<GridTile> tiles = new List<GridTile>();
        if (spell == null)
            return tiles;

        GridTile currentTile = middleTile;

        for (int i = 0; i < spell.aoe.Length; i++)
        {
            if (spell.aoe[i] != SpellDirection.Middle)
                GetSpellTile(ref currentTile, spell.aoe[i]);
            else
            {
                currentTile = middleTile;
                continue;
            }

            if (currentTile == null || tiles.Contains(currentTile))
                continue;

            tiles.Add(currentTile);
        }

        return tiles;
    }
    void GetSpellTile(ref GridTile currentTile, SpellDirection direction)
    {
        if (currentTile == null || direction == SpellDirection.Middle)
            return;

        Vector2Int v = currentTile.m_GridPosition;
        Vector2Int facing = facingDirection;

        if (direction == SpellDirection.Top)
            v.y += 1;
        else if (direction == SpellDirection.Down)
            v.y -= 1;
        else if (direction == SpellDirection.Left)
            v.x -= 1;
        else if (direction == SpellDirection.Right)
            v.x += 1;
        else if (direction == SpellDirection.TopLeft)
        {
            v.x -= 1;
            v.y += 1;
        }
        else if (direction == SpellDirection.TopRight)
        {
            v.x += 1;
            v.y += 1;
        }
        else if (direction == SpellDirection.DownLeft)
        {
            v.x -= 1;
            v.y -= 1;
        }
        else if (direction == SpellDirection.DownRight)
        {
            v.x += 1;
            v.y -= 1;
        }

        else if (direction == SpellDirection.Facing)
        {
            //Vector2Int facing = GetComponent<GridObject>().m_FacingDirection;
            //Debug.Log("pLayer casting and facgin" + gameObject.name + "//" + facing);

            if (facing == dirvectorW)
            {
                v.y += 1;
            }
            if (facing == dirvectorA)
            {
                v.x -= 1;
            }
            if (facing == dirvectorS)
            {
                v.y -= 1;
            }
            if (facing == dirvectorD)
            {
                v.x += 1;
            }
        }
        else if (direction == SpellDirection.FacingLeft)
        {
            if (facing == dirvectorW)
            {
                v.x -= 1;
            }

            if (facing == dirvectorS)
            {

                v.x -= 1;
            }

            if (facing == dirvectorA)
            {

                v.y -= 1;
            }

            if (facing == dirvectorD)
            {

                v.y += 1;
            }


        }


        else if (direction == SpellDirection.FacingRight)
        {
            if (facing == dirvectorW)
            {
                v.x += 1;
            }

            if (facing == dirvectorS)
            {
                v.x += 1;
            }

            if (facing == dirvectorA)
            {
                v.y += 1;
            }

            if (facing == dirvectorD)
            {

                v.y -= 1;
            }
        }
        currentTile = GridManager.Instance.GetGridTileAtPosition(v);
    }


    [Server]
    void UpdateCooldowns()
    {
        lock (spellCooldown)
        {
            foreach (var spell in spellCooldown.ToList())
            {
                float value = spell.Value - Time.deltaTime;
                spellCooldown[spell.Key] = value;
                if (value <= 0)
                    spellCooldown.Remove(spell.Key);
            }
        }

        lock (coreSpellCooldown)
        {
            foreach (var type in coreSpellCooldown.ToList())
            {
                float value = type.Value - Time.deltaTime;
                coreSpellCooldown[type.Key] = value;
                if (value <= 0)
                    coreSpellCooldown.Remove(type.Key);
            }
        }
    }

    [Server]
    public void TakeDamage(float damage)
    {
        float prevHealth = currentHealth;
        currentHealth -= damage;
        currentHealth = Mathf.Clamp(currentHealth, 0, maxHealth);
        RpcSetHealth(prevHealth, currentHealth);
        if (currentHealth <= 0)
            DoDie();
    }


    [Server]
    public void HealHealth(float value)
    {
        float prevHealth = currentHealth;
        currentHealth += value;
        currentHealth = Mathf.Clamp(currentHealth, 0, maxHealth);
        RpcSetHealth(prevHealth, currentHealth);
    }


    [SerializeField] Slider healthSlider;

    [ClientRpc]
    public void RpcSetHealth(float prev, float newHealth)
    {
        Vector3 floatingTextOffset = new Vector3(0, 2.3f, 0);
        Debug.Log(healthSlider.transform.parent.transform.parent.transform.parent.name);

        gameObject.GetComponentInChildren<Slider>().value = newHealth / (100);

        bool healed = newHealth > prev;
        Instantiate(floatingTextPrefab, transform.position + floatingTextOffset, Quaternion.identity).GetComponent<PopUpText>().Init(newHealth - prev, newHealth > prev);

    }


    void OnHealthChange(float previousHealth, float newHealth)
    {
        healthSlider.value = (newHealth / (100));

        bool healed = newHealth > previousHealth;
        ChangeHealthBarUI();
        //Instantiate(floatingTextPrefab, transform.position, Quaternion.identity).GetComponent<PopUpText>().Init(newHealth - previousHealth, newHealth > previousHealth);
    }


    void OnManaChange(float previousMana, float newMana)
    {
	......
	............
	..................

    }


    [Server]
    void DoDie()
    {
        exp -= expLossOnDeath;
        exp = Mathf.Clamp(exp, 0, float.MaxValue);
        RpcDoDie();
        Respawn();
        RpcRespawn();

    }


    [ClientRpc]
    void RpcDoDie()
    {
        Debug.Log("Player " + name + " has died!");

    }


    [Server]
    void Respawn()
    {
        currentHealth = maxHealth;
        currentMana = maxMana;
        RpcSetHealth(0, currentHealth);
        GridTile tile = GridManager.Instance.getRandomTile();
        while (_gridMovement.TryMoveTo(tile, false, true, false) != MovementResult.Moved)
            tile = GridManager.Instance.getRandomTile();

    }

    [ClientRpc]
    void RpcRespawn()
    {
        currentHealth = maxHealth;
        currentMana = maxMana;
        RpcSetHealth(0, currentHealth);
        GridTile tile = GridManager.Instance.getRandomTile();
        while (_gridMovement.TryMoveTo(tile, false, true, false) != MovementResult.Moved)
            tile = GridManager.Instance.getRandomTile();
    }
    void OnEXPChange(float previousEXP, float newEXP)
    {
        Debug.Log("Previous EXP: " + previousEXP + " New EXP: " + newEXP);
    }

    void HealthRegen()
    {
        float temp = currentHealth + healthRegen;
        temp = Mathf.Clamp(temp, 0, maxHealth);
        currentHealth = temp;
    }
    void ManaRegen()
    {
        float temp = currentMana + manaRegen;
        temp = Mathf.Clamp(temp, 0, maxMana);
        currentMana = temp;
    }

    private void ChangeHealthBarUI()
    {
        if (healthSlider.value < 0.35)
        {
            healthSlider.transform.GetComponentInChildren<HealthBarReactions>().gameObject.GetComponentInChildren<Image>().color = Color.red;
        }

        if (healthSlider.value < 0.6 && healthSlider.value > 0.35)
        {
            healthSlider.transform.GetComponentInChildren<HealthBarReactions>().gameObject.GetComponentInChildren<Image>().color = Color.yellow;
        }
        if (healthSlider.value >= 0.6)
        {
            healthSlider.transform.GetComponentInChildren<HealthBarReactions>().gameObject.GetComponentInChildren<Image>().color = Color.green;
        }
    }


    [Command]
    public void CmdChangePlayersPrefabFromProfession(int prof)
    {
        if (prof == 0)
        {
            Debug.Log("got knight");
            RpcChangePlayersPrefabFromProfession(0);
        }

        if (prof != 0)
        {
            knightPrefab.active = false;
        }

        if (prof == 1)
        {
            wizardPrefab.active = true;
            GetComponent<MovementEvents>().my_Animator = wizardPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = wizardPrefab.GetComponent<Animator>();
            RpcChangePlayersPrefabFromProfession(1);
        }

        if (prof == 2)
        {
            RpcChangePlayersPrefabFromProfession(2);
            priestPrefab.active = true;
        }

        if (prof == 3)
        {
            rangerPrefab.active = true;
            RpcChangePlayersPrefabFromProfession(3);

        }
        RpcChangePlayersPrefabFromProfession(profession);

    }


    [ClientRpc]
    public void RpcChangePlayersPrefabFromProfession(int prof)
    {

        if(gameObject.name != "MyLocalPlayer") {
            transform.GetComponentInChildren<HideObjectsOnCollision>().gameObject.GetComponent<BoxCollider>().enabled = false;
        }
        
        if (prof == 0)
        {
            Debug.Log("got knight");
        }

        if(prof != 0) {
            knightPrefab.active = false;
        }

        if (prof == 1)
        {
            Debug.Log("got wizard");
            wizardPrefab.active = true;

            GetComponent<MovementEvents>().my_Animator = wizardPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = wizardPrefab.GetComponent<Animator>();
      
        }

        if (prof == 2)
        {
            Debug.Log("got priest " + profession + gameObject.name);
            priestPrefab.active = true;
            GetComponent<MovementEvents>().my_Animator = priestPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = priestPrefab.GetComponent<Animator>();
        
        }

        if (prof == 3)
        {
            Debug.Log("got ranger " + profession + gameObject.name);
            rangerPrefab.active = true;
            GetComponent<MovementEvents>().my_Animator = rangerPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = rangerPrefab.GetComponent<Animator>();
        
        }

        if (profession == 0)
        {

        }

        if (profession != 0)
        {
            knightPrefab.active = false;
        }

        if (profession == 1)
        {
            
            wizardPrefab.active = true;
            GetComponent<MovementEvents>().my_Animator = wizardPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = wizardPrefab.GetComponent<Animator>();

        }

        if (profession == 2)
        {
            priestPrefab.active = true;
            GetComponent<MovementEvents>().my_Animator = priestPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = priestPrefab.GetComponent<Animator>();

        }

        if (profession == 3)
        {
            rangerPrefab.active = true;
            GetComponent<MovementEvents>().my_Animator = rangerPrefab.GetComponent<Animator>();
            GetComponent<AdvancedNetworkAnimator>().animator = rangerPrefab.GetComponent<Animator>();
        }


    }


    public IEnumerator changePrefabSkin(int prof)
    {
        yield return new WaitForSeconds(3);
        Debug.Log("profoforofrofrof" + prof);
        GameObject.Find("MyLocalPlayer/ModelHolder/Skin_1/warrior/").gameObject.SetActiveRecursively(false);

    }

}


   


   