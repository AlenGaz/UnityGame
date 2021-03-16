using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Mirror;

public class ShowFloorsOnTrigger : MonoBehaviour
{


    // HARDCODED THAT THE NAME OF LOCAL PLAYER IN UNITY IS "MYLOCALPLAYER"

    public GameObject boxHolder;
    public GameObject character;


    private void Awake()
    {
        PlayerUpdated(ClientScene.localPlayer);
        LocalPlayerAnnouncer.OnLocalPlayerUpdated += PlayerUpdated;

    }




    private void OnDestroy()
    {
        LocalPlayerAnnouncer.OnLocalPlayerUpdated -= PlayerUpdated;
    }

    private void PlayerUpdated(NetworkIdentity localPlayer)
    {
        if (localPlayer != null && localPlayer.isLocalPlayer)
        {

            character = localPlayer.gameObject;
            boxHolder = character.GetComponentInChildren<HideObjectsOnCollision>().gameObject;

            for (int i = 0; i < transform.childCount; i++)
            {
                transform.GetChild(i).gameObject.GetComponent<ShowFloorsOnTrigger>().enabled = true;
                transform.GetChild(i).gameObject.GetComponent<ShowFloorsOnTrigger>().GetComponent<MeshRenderer>().enabled = false;
                
            }

        }
    }

    void OnTriggerEnter(Collider collision)
    {
        GameObject other = collision.gameObject;

        try
        {
            if (other.name == "MyLocalPlayer" && collision.GetType() != typeof(SphereCollider))
                boxHolder.GetComponentInChildren<BoxCollider>().isTrigger = false;
                boxHolder.layer = LayerMask.NameToLayer("Ignore Raycast");
        }
        catch (System.Exception) { }

    }
}

