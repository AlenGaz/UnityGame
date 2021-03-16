using System;
using Mirror;
using UnityEngine;

public class LocalPlayerAnnouncer : NetworkBehaviour
{
    

    public static event Action<NetworkIdentity> OnLocalPlayerUpdated;
    void Start()
    {
        
    }

    public override void OnStartLocalPlayer()
    {
        base.OnStartLocalPlayer();
        OnLocalPlayerUpdated?.Invoke(base.netIdentity);

        
    }

    private void OnDestroy()
    {
        if (base.isLocalPlayer)
        {
            OnLocalPlayerUpdated?.Invoke(null);
            
        }
    }

  
}
