
using UnityEngine;
using UnityEngine.UI;
using Mirror;
using TMPro;
using System;

public class ChatBehaviour : NetworkBehaviour
{
    [SerializeField] private GameObject chatUI = null;
    [SerializeField] private TMP_Text chatText = null;
    [SerializeField] private TMP_InputField inputField = null;

    private static event Action<string> OnMessage;
    public override void OnStartAuthority()
    {
        /*
        chatUI.SetActive(true);
        OnMessage += HandleNewMessage;  */
    }

    [ClientCallback]
    private void OnDestroy()
    {
        if (!hasAuthority) { return; }

        OnMessage -= HandleNewMessage;
    }

    private void HandleNewMessage(string message)
    {
        chatText.text += message;
    }

    [Client]
    public void Send(string message)
    {
        if (!Input.GetKeyDown(KeyCode.Return)) { return; }

        if (string.IsNullOrWhiteSpace(message)) { return; }
        CmdSendMessage(inputField.text);
        inputField.text = string.Empty;

    }

    [Command]
    private void CmdSendMessage(string message)
    {
        // validate , filter profanity etc.. here. message is modified to show id in brackets
        RpcHandleMessage($"[{connectionToClient.connectionId}]:{message}");
    }

    [ClientRpc]
    private void RpcHandleMessage(string message)
    {
        OnMessage?.Invoke($"\n{message}");
    }
}




