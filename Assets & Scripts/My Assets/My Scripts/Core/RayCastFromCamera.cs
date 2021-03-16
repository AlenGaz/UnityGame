using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Mirror;
using System;

public class RayCastFromCamera : MonoBehaviour
{
    public GameObject character;
    Vector3 rayOffset = new Vector3(0, 0, 0.45f);
    public GameObject boxHolder;
    [SerializeField] float TresholdIntersection = -0.85f; //this is how big the difference between 
    [SerializeField] float TresholdHeight = 1f;
    //ray collission and floor above is


    //used for toggling camera with P
    private bool zoomBack = false;




    public void Awake()
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
        if (localPlayer != null && localPlayer.isLocalPlayer == true)
        {
            character = localPlayer.gameObject;
            boxHolder = localPlayer.GetComponentInChildren<HideObjectsOnCollision>().gameObject;
        }

    }

    void FixedUpdate()
    {

        RaycastHit hit;

        if (Physics.Raycast(transform.position, character.transform.position - transform.position, out hit, 30))
        {

            if (hit.collider.gameObject.transform.position.y > character.transform.position.y + TresholdHeight)

                checkHeightOfCollisionAndToggleHideHigherFloors(hit);
        }
        if (Input.GetKeyDown(KeyCode.Y))
        {
            setHideHigherFloorsFalse();
        }

    }


    public void checkHeightOfCollisionAndToggleHideHigherFloors(RaycastHit hit)
    {
        setHideHigherFloorsTrue();

    }



    private void setHideHigherFloorsFalse()
    {

        boxHolder.GetComponentInChildren<BoxCollider>().isTrigger = false;

    }

    private void setHideHigherFloorsTrue()
    {
        if (boxHolder == null)
            return;
        boxHolder.GetComponentInChildren<BoxCollider>().isTrigger = true;
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawRay(transform.position, character.transform.position + rayOffset - transform.position);
    }
}
