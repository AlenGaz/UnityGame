using Mirror;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CommandDemo : NetworkBehaviour

{
    // Start is called before the first frame update
    public override void OnStartLocalPlayer()
    {
        base.OnStartLocalPlayer();
        StartCoroutine(__RandomizeColor());

    }

    private void SetRenderer(bool enabler)
    {
        //SpriteRenderer renderer = GetComponent<SpriteRenderer>();
        MeshRenderer renderer = GetComponent<MeshRenderer>();
        renderer.enabled = enabler;
    }

    private IEnumerator __RandomizeColor()
    {
        WaitForSeconds wait = new WaitForSeconds(1f);
        while (true)
        {
            CmdChangeColor();
            yield return wait;
        }
    }

    [Command]
    private void CmdChangeColor()
    {
        Debug.Log("Cmd Change Color is Called");
        bool enabler = false;
        SetRenderer(enabler);

    }
}
