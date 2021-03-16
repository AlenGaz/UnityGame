using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Mirror;
using System;

public class CharacterInput : NetworkBehaviour
{
    private GameObject inputFieldSlot;
    private InputField inputField;
    [SerializeField] public Transform TargetHighlighter;
    [SerializeField] public Transform currentTarget;
    public GridObject _gridObject;

    // Variables for managing targeting characters/enemies on gridtiles
    private Vector3 TargetHighlighterDefaultPos = new Vector3(999, 15, 999);
    protected GridTile _currentTargetTile;
    protected GridTile _previousTargetTile;
    [SerializeField] public bool gridObjectOnTile = false;
    protected GridObject _currentTargetGridObject;

    // Variables for pushing enemy
    private GridTile pushTargetTile;
    private GridObject pushTarget;
    private float pushDistance = 2f;
    private _Player _pluto;
    [SerializeField] _Player player;


    //public GameObject mwallPrefab; not need i think
    //public NetworkIdentity mwallNetId;
    private Vector2Int targetSpellPosition;
    private GridObject instantiatedMagicWall;
    bool wait = true;


    //Spell Bools ATM
    public bool mWallBool = false;
    private bool SdBool = false;
    private bool teleportBool = false;

    public Vector2Int playersPosition; // for teleport/blitz effect

    private bool hasteBool = false;
    [SerializeField] public Cooldown _cooldown;
    private bool healBool;

    [SerializeField] GameObject projectilePrefab;

    public Cooldown Cooldown { get { return _cooldown; } }


    void Awake()
    {
        Debug.Log("Script requires that local player prefab is called MyLocalPlayer here...");
        inputFieldSlot = GameObject.Find("Chat/InputField");
        inputField = inputFieldSlot.GetComponent<InputField>();
        TargetHighlighter = GameObject.Find("Target Highlighter").transform;
        //mwallNetId = mwallPrefab.GetComponent<NetworkIdentity>();

        _pluto = GetComponent<_Player>();

        _gridObject = this.gameObject.GetComponent<GridObject>();



    }


    void Update()
    {

        if (Input.GetMouseButtonDown(0))
        {
            if (GridManager.Instance != null)
            {
                Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
                if (Physics.Raycast(ray, out RaycastHit hit, 100f))
                {
                    _Player p = hit.collider.GetComponent<_Player>();
                    if (p != null)
                    {
                        Vector2Int target = p._gridObject.m_GridPosition;
                        CmdAttack(target);
                    }
                }
            }
        }

        if (Input.GetMouseButtonDown(1))
        {

            Plane p = new Plane(Camera.main.transform.forward, transform.position);
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;

            if (Physics.Raycast(ray, out hit, 100))
            {
                if (hit.collider.gameObject.CompareTag("Character") || hit.collider.gameObject.CompareTag("Enemy") || hit.collider.gameObject.CompareTag("Player"))
                {

                    currentTarget = hit.collider.gameObject.transform;

                    TargetHighlighter.transform.parent = currentTarget;
                    TargetHighlighter.transform.position = currentTarget.position;

                }
            }
            if (GridManager.Instance.m_HoveredGridTile != null)
            {
                _currentTargetTile = GridManager.Instance.m_HoveredGridTile;
                _currentTargetGridObject = GridManager.Instance.GetGridObjectAtPosition(_currentTargetTile.m_GridPosition);

                if (_currentTargetGridObject == null) { return; }

                if (_currentTargetGridObject.CompareTag("Character") || _currentTargetGridObject.CompareTag("Player") || _currentTargetGridObject.CompareTag("Enemy"))
                {
                    currentTarget = _currentTargetGridObject.gameObject.transform;
                    TargetHighlighter.transform.parent = currentTarget.transform;
                    TargetHighlighter.transform.position = currentTarget.position;

                }

                if (_currentTargetGridObject.CompareTag("Teleport"))
                {
                    Debug.Log(_gridObject.name);
                    if (_gridObject.name == "MyLocalPlayer" && Vector2.Distance(_gridObject.m_GridPosition, _currentTargetGridObject.m_GridPosition) < 2)
                    {
                        _currentTargetGridObject.GetComponent<Teleport>().startTeleportTrigger(_gridObject, _gridObject.m_CurrentGridTile);
                    }

                }

            }
        }


        if (inputField.isFocused && (Input.GetKey(KeyCode.Return)))
        {
            string msg = inputField.text;
            inputField.text = "";


            if (string.IsNullOrEmpty(msg))
                return;

            _Player l = _Player.local;
            if (l == null)
                return;
            l.SendChatMessage(msg);
            inputField.DeactivateInputField();
        }

        if (Input.GetKeyDown(KeyCode.Return) && !Input.GetKeyDown(KeyCode.A))
        {
            inputField.ActivateInputField();
        }
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            inputField.DeactivateInputField();
            TargetHighlighter.position = TargetHighlighterDefaultPos;
            currentTarget = null;
        }



        PushObject();

        if (Input.GetKeyDown(KeyCode.Alpha4))
        {
            Debug.Log("ISHASTEBOOL?!?" + hasteBool);
            if (!hasteBool)
            {
                hasteBool = true;
                StartCoroutine("abilityForSeconds");
                
            }
        }

        if (Input.GetKeyDown(KeyCode.Alpha5))
        {
            mWallBool = true;
            StartCoroutine("PollForMouseClick");
        }

        if (Input.GetKeyDown(KeyCode.Alpha6))
        {
            SdBool = true;
            StartCoroutine("PollForMouseClick");
        }


        if (Input.GetKeyDown(KeyCode.T))
        {
            teleportBool = true;
            StartCoroutine("PollForMouseClick");
        }



        //Skriv för att klicka och dra droppade items 
        //(printa ut gameObjectet först) sen testar jag dra in dem i character ui sloten

    }


    private void PushObject()
    {
        if (Input.GetMouseButtonDown(0))
        {
            // WHY THE FUCK IS gameObject,..,.m_GridPosition the same as the pushtargets?!?
            if (GridManager.Instance.m_HoveredGridTile != null && (Mathf.Abs(Vector2.Distance(GridManager.Instance.m_HoveredGridTile.m_GridPosition, this.gameObject.GetComponent<GridObject>().m_GridPosition)) < 2f))
            {
                pushTarget = GridManager.Instance.GetGridObjectAtPosition(GridManager.Instance.m_HoveredGridTile.m_GridPosition);
            }
        }

        else if (Input.GetMouseButtonUp(0))
        {

            if (pushTarget != null)
            {
                if (GridManager.Instance.m_HoveredGridTile != pushTarget.GetComponent<GridObject>().m_CurrentGridTile)
                {
                    Vector2 DiffVec = new Vector2(0, 0);
                    pushTargetTile = GridManager.Instance.m_HoveredGridTile;
                    // TRYING A DIFFERENT WAY TO MAKE SURE U HAVE TO BE CLOSE TO PUSH
                    DiffVec = pushTargetTile.m_GridPosition - gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition;
                    //Debug.Log(Mathf.Abs(Vector2.Distance(pushTargetTile.m_GridPosition, this.gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition)) + "Kahbo");
                    //Debug.Log(Mathf.Abs(Vector2.Distance(DiffVec, gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition))+  "Kahbo");
                    if (Mathf.Abs(Vector2.Distance(pushTargetTile.m_GridPosition, this.gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition)) > 3)
                    {
                        return;
                    }

                }

                if ((Vector3.Distance(pushTargetTile.transform.position, pushTarget.transform.position) < 2) && (Vector3.Distance(pushTargetTile.transform.position, pushTarget.transform.position) > 1))
                {
                    //sending the pushers position too so that it may be calculated server-side the distance between 
                    // pusher and pusheed
                    _pluto.CmdPushTarget(transform.position, pushTarget.gameObject, pushTargetTile.m_GridPosition);
                    Debug.Log("EYYYYYYYYYYKURWO");
                    pushTarget = null;
                }
            }
        }
    }

    public void SpawnWall()
    {

        if (GridManager.Instance.m_HoveredGridTile != null)
        {
            if (Input.GetKeyDown(KeyCode.Escape)) { StopCoroutine("PollForMouseClick"); return; }
            targetSpellPosition = GridManager.Instance.m_HoveredGridTile.m_GridPosition;
            //Debug.Log("NetId of Wall" + mwallNetId); 
            //instantiatedMagicWall = GridManager.Instance.InstantiateGridObject(mwallPrefab.GetComponent<GridObject>(), mwallPosition);
            _pluto.CmdSpawnObjectInPosition("mWall", targetSpellPosition);
            //instantiatedMagicWall.transform.parent = transform;
            StopCoroutine("PollForMouseClick");
            wait = true;
            mWallBool = false;
        }
    }

    public void SpawnSd()
    {
        if (GridManager.Instance.m_HoveredGridTile != null)
        {
            if (Input.GetKeyDown(KeyCode.Escape)) { StopCoroutine("PollForMouseClick"); return; }

            targetSpellPosition = GridManager.Instance.m_HoveredGridTile.m_GridPosition;
            _pluto.CmdSpawnObjectInPosition("Sd", targetSpellPosition);


            StopCoroutine("PollForMouseClick");
            wait = true;
            SdBool = false;

        }
    }


    public void teleportPlayer()
    {
        if (GridManager.Instance.m_HoveredGridTile != null)
        {
            if (Input.GetKeyDown(KeyCode.Escape)) { return; }
            targetSpellPosition = GridManager.Instance.m_HoveredGridTile.m_GridPosition;
            if (Vector2.Distance(targetSpellPosition, gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition) < 5) //making sure its max 4 tiles away

                playersPosition = gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition;
            {
                _pluto.CmdTeleportObject(gameObject, playersPosition, targetSpellPosition);
                StopCoroutine("PollForMouseClick");

                wait = true;
                teleportBool = false;
            }
        }
    }


    public void hastePlayer()
    {
        //hasteBool = true;
        _pluto.CmdSpawnObjectInPosition("Wings", gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition);
    }


    public void healPlayer()
    {
        _pluto.CmdSpawnObjectInPosition("Heal", gameObject.GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition);
    }



    public IEnumerator PollForMouseClick()
    {
        while (wait)
        {
            if (Input.GetMouseButtonDown(0))
            { // Setting next input to be a spell input also stopping movement and using bools to determine which function to call
                GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
                if (mWallBool) { SpawnWall(); }
                if (SdBool) { SpawnSd(); }
                if (teleportBool) { teleportPlayer(); }
            }

            if (Input.GetKeyDown(KeyCode.Escape))
            {
                Debug.Log("Returned on Escape");
                //StopCoroutine("PollForMouseClick");
                wait = false;
                yield return null;
            }

            yield return null;
            wait = true;
        }
    }

    public IEnumerator abilityForSeconds() // ablitities for Seconds are client side atm
    {
        if (hasteBool)
        {
            Debug.Log("in AbilityForSeconds");
            hastePlayer();
            GetComponent<KeyboardDrivenController>().normalMoveSpeed = 0.15f;
            GetComponent<KeyboardDrivenController>().diagonalMoveSpeed = 0.27f;
            //Cooldown.DefaultDuration = 0.16f;
            GetComponent<GridMovement>().Cooldown.DefaultDuration = 0.17f;
            yield return new WaitForSeconds(13);
            GetComponent<KeyboardDrivenController>().normalMoveSpeed = 0.27f;
            //Cooldown.DefaultDuration = 0.28f;
            GetComponent<GridMovement>().Cooldown.DefaultDuration = 0.29f;
            hasteBool = false;
        }
    }

    [Command]
    void CmdAttack(Vector2Int target)
    {
        Debug.Log("CMD Attack at target: " + target);
        GridObject obj = GridManager.Instance.GetGridObjectAtPosition(target);
        if (obj != null)
        {
            Debug.Log("obj isnt null, tag: " + obj.tag);
            if (obj.CompareTag("Player"))
            {
                if (obj.GetComponent<_Player>() != player)
                {
                    GameObject go = Instantiate(projectilePrefab, transform.position, transform.rotation);
                    go.transform.LookAt(obj.transform);
                    go.GetComponent<Projectile>().Init(obj.gameObject);
                }
            }
        }
    }
}