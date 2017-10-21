using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EverythingManager : MonoBehaviour {

	public Material everything;
	public float volumeSensitivity = 1000;
	[Range(0, 10)]public float volumeInertia = 0.1f;

	float bubbleRatio = 0;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		bubbleRatio = Mathf.MoveTowards(bubbleRatio, Mathf.Lerp(1, 10, MicInput.MicLoudness * volumeSensitivity), 
				volumeInertia * Time.deltaTime);
		everything.SetFloat("_HeadBubble", bubbleRatio);
	}
}
