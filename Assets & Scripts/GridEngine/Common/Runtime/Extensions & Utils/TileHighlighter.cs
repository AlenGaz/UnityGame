using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TileHighlighter : MonoBehaviour
{

    [Header("Offset Position")]
    public Vector3 m_Offset = Vector3.zero;
    [Header("Unhighlighted Position")]
    public Vector3 m_UnHighlightedPosition = new Vector3(999, 0, 999);

    protected GridTile _currentTargetTile;
    protected GridTile _previousTargetTile;
    [SerializeField] public bool gridObjectOnTile = false;


    private void Awake()
    {
        //SetLayerRecursively(gameObject,3);
    }


    // Update is called once per frame
    void Update() {
        if (GridManager.Instance.m_HoveredGridTile != null) {
            // Update the currently and previous hovered tiles
            if (GridManager.Instance.m_HoveredGridTile != _currentTargetTile) {
                _previousTargetTile = _currentTargetTile;
                _currentTargetTile = GridManager.Instance.m_HoveredGridTile;
            
            }
        } else {
            // Reset the variable
            if (_currentTargetTile != null) {
                _previousTargetTile = _currentTargetTile;
                _currentTargetTile = null;
            }
        }

        // Set the highlighter's position
        if (_currentTargetTile != null) {
            transform.position = _currentTargetTile.m_WorldPosition + m_Offset;
            //gridObjectOnTile = _currentTargetTile.GetComponent<GridManager>().GetGridObjectAtPosition(_currentTargetTile.m_GridPosition).gameObject.transform;
            if (_currentTargetTile.IsTileOccupied())
            {
                gridObjectOnTile = true;
                //print(_currentTargetTile.m_OccupyingGridObjects[0]);
            }
        } else {
            transform.position = m_UnHighlightedPosition;
            //gridObjectOnTile = false;
        }
    }

    void SetLayerRecursively(GameObject obj, int newLayer)
    {
        if (null == obj)
        {
            return;
        }

        obj.layer = newLayer;

        foreach (Transform child in obj.transform)
        {
            if (null == child)
            {
                continue;
            }
            Debug.Log(child.gameObject.layer + "Changed Layer" + "name;" + child.gameObject.name);
            SetLayerRecursively(child.gameObject, newLayer);
        }
    }

}
