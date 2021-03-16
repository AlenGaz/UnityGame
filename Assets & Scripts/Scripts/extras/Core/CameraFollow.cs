using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Mirror;

public class CameraFollow : MonoBehaviour
{
    [SerializeField] Transform target;
    [SerializeField] float smoothing = 5f;

    [SerializeField] public Vector3 offset;
    [SerializeField] Vector3 targetCamPos;

    public Vector3 standardOffset = new Vector3(-1f, 11.5f, -5.5f);
    Camera cam;


    private void Awake()
    {

        cam = GetComponent<Camera>();


        PlayerUpdated(ClientScene.localPlayer);
        LocalPlayerAnnouncer.OnLocalPlayerUpdated += PlayerUpdated;

    }


    private void OnDestroy()
    {
        LocalPlayerAnnouncer.OnLocalPlayerUpdated -= PlayerUpdated;
    }


    void LateUpdate()
    {
        if (target == null)
            return;

        targetCamPos = target.position + offset;
        transform.position = Vector3.Lerp(transform.position, targetCamPos, smoothing * Time.deltaTime);
    }


    private void PlayerUpdated(NetworkIdentity localPlayer)
    {
        if (localPlayer != null && localPlayer.isLocalPlayer == true)
        {
            target = localPlayer.transform;
            offset = standardOffset;
        }
    }

    
}
