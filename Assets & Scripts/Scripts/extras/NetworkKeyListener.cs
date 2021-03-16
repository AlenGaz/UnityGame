using Mirror;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NetworkKeyListener : MonoBehaviour
{

    public bool ClientBuild;
    public bool ServerBuild;
    public bool Both_Host_Build;


    private void Start()
    {
        if (ClientBuild)
        {
            NetworkingManager.getInstance.StartClient();
            Destroy(this);
        }
        if (Both_Host_Build)
        {
            NetworkingManager.getInstance.StartHost();
            Destroy(this);
        }
        if (ServerBuild)
        {
            NetworkingManager.getInstance.StartServer();
            Destroy(this);
        }

    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
        {
            NetworkingManager.getInstance.StartServer();
    
            Destroy(this);
        }
        else if (Input.GetKeyDown(KeyCode.W))
        {
            NetworkingManager.getInstance.StartHost();
            Destroy(this);
        }
        else if (Input.GetKeyDown(KeyCode.E))
        {
            NetworkingManager.getInstance.StartClient();
            Destroy(this);
        }    
    }
}
