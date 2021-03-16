using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using Mirror;
using System;

//Note: add script to player gameobject
//      when multiplayer game starts
//      turns off scripts off other players that are not you
//      why? so you dont control them
// ALSO contains reference to Animator on character

public class TurnOffRemotePlayer : NetworkBehaviour
{
    [SerializeField] public GameObject SpawnTile;
    //Vector2 SpawnPosition = new Vector2(3, 2);
    [SerializeField] GridObject PlayerSpawn;
    public Animator m_Animator;



    public void LateUpdate()
    {
        // just a test to see if there is a problem with other players boxcolliders
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Debug.Log("REMOVING PLAYERS BOXCOLLIDER");
            if (this.isLocalPlayer != true) {
                
                transform.GetComponentInChildren<HideObjectsOnCollision>().gameObject.GetComponent<BoxCollider>().enabled = false;
                transform.GetComponentInChildren<HideObjectsOnCollision>().gameObject.layer = LayerMask.NameToLayer("Ignore Raycast");
            }
        }
    }

    private void Start()
    {
        string id = string.Format("{0}", this.netId);
        PlayerData scr = this.GetComponent<PlayerData>();
        PlayerSpawn = this.gameObject.GetComponent<GridObject>();
        this.gameObject.layer = 2;
        

        scr.SetPlayerCaption("x");


        if (this.isLocalPlayer == true)
        {
            scr.enabled = true;
            scr.SetPlayerCaption(id);
            scr.SetTitle("MultiPlayer #" + id);
            scr.InstantiateAsGridObjectOnStart();
            gameObject.name = "MyLocalPlayer";
            m_Animator = gameObject.GetComponentInChildren<LocalPlayerAnimatorReference>().GetComponentInChildren<Animator>();

            if (GridManager.Instance!=null)
            GridManager.Instance.InstantiateGridObject(gameObject.GetComponent<GridObject>(), scr.PlayerSpawnTile.GetComponent<GridTile>().m_GridPosition);
        }

        else
        {
            scr.SetPlayerCaption(id);
            scr.enabled = false;
            transform.name = "RemotePlayer";

            //remove movement scripts on players
            GetComponent<GridMovement>().enabled = true;
            GetComponent<KeyboardDrivenController>().enabled = false;
            GetComponent<MouseDrivenController>().enabled = false;
            m_Animator = transform.GetComponentInChildren<LocalPlayerAnimatorReference>().GetComponentInChildren<Animator>();
            GetComponent<UI_non_rotate>().rotation = transform.rotation;
            //transform.GetComponentInChildren<HideObjectsOnCollision>().gameObject.layer = 2;
            int idToInt = Int32.Parse(id);
            //set the remote players to gridobjects



            if (GridManager.Instance!=null)
            GridManager.Instance.InstantiateGridObject(transform.GetComponent<GridObject>(),
                scr.PlayerSpawnTile.GetComponent<GridTile>().m_GridPosition + new Vector2Int(idToInt,idToInt));
            //remove the remote players boxcollider trigger
            transform.GetComponentInChildren<HideObjectsOnCollision>().gameObject.GetComponent<BoxCollider>().enabled= false;
            transform.GetComponentInChildren<HideObjectsOnCollision>().gameObject.layer = 2;

            
        }



    }
} 