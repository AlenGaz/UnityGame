using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ChatManager : MonoBehaviour
{
    public static ChatManager getInstance;
    void Awake() { getInstance = this; }

    [SerializeField] GameObject messagePrefab;
    [SerializeField] Transform spawnLocation;
    [SerializeField] int maxMessages = 4500;
    [SerializeField] Button btn;
    [SerializeField] InputField input;

    List<GameObject> chatMessages = new List<GameObject>();

    void Start()
    {
        onButtonClick();
    } 

    public void GetMessage(string message)
    {
  
        if (chatMessages.Count >= maxMessages)
        {
            Destroy(chatMessages[0]);
            chatMessages.RemoveAt(0);
        }

        GameObject msg = Instantiate(messagePrefab, spawnLocation);
        msg.GetComponent<Text>().text = message;
        chatMessages.Add(msg);

        // Added to make chat "Auto-Scroll" 
        if (chatMessages.Count % 7 == 0)
        {
            Debug.Log("Should scroll now");
            GetComponentInChildren<Scrollbar>().value = 0.1f;
        }
       
     
    }

    public void onButtonClick()
    {
        btn.onClick.AddListener(delegate
        {
            string msg = input.text;
            input.text = "";
            Debug.Log("onButtonClick called");

            if (string.IsNullOrEmpty(msg))
                return;

            _Player l = _Player.local;
            if (l == null)
                return;

            l.SendChatMessage(msg);
            
        });
    }
}