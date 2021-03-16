using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Mirror;

public class PlayerData : MonoBehaviour
{
    private TextMesh tm = null;
    private Text ui = null;

    [SerializeField] public GameObject PlayerSpawnTile;
    [SerializeField] public GameObject PlayerPrefab;

    
    public void SetPlayerCaption(string caption)
        {
        }


    public void SetTitle(string caption)
    {
        if (ui == null)
        {
            //ui = GameObject.Find("txtTitle").GetComponent<Text>();
        }

        if (ui != null)
        {
            ui.text = caption;
        }
    }

    public void InstantiateAsGridObjectOnStart()
    {
        Debug.Log("Instantiated player as gridobject");
        StartCoroutine(t());
    }

    IEnumerator t()
    {
        while (GridManager.Instance == null)
        {
            print("f");
            yield return null;
        }
        print("Grid manager isnt null now");
        GridManager.Instance.InstantiateGridObject(PlayerPrefab.GetComponent<GridObject>(), PlayerSpawnTile.GetComponent<GridTile>().m_GridPosition);
    }

}
