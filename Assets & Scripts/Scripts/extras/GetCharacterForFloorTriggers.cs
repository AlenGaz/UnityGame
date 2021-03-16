using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Mirror;

public class GetCharacterForFloorTriggers : MonoBehaviour
{

    public GameObject character;
    public bool HideMeshRendererChilden = true;

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
            for (int i = 0; i < transform.childCount; i++)
            {
                transform.GetChild(i).gameObject.GetComponent<ShowFloorsOnTrigger>().enabled = true;
                transform.GetChild(i).gameObject.GetComponent<ShowFloorsOnTrigger>().GetComponent<MeshRenderer>().enabled = false;
            }

        }
    }


}
