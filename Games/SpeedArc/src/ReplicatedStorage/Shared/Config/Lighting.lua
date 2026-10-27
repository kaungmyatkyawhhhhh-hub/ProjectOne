-- Lighting presets per area (Lighting note). LightingController applies the area you are in.
return {
	Hub = {
		ClockTime = 16.5,
		GeographicLatitude = 35,
		Brightness = 2.4,
		Ambient = Color3.fromHex("#6B7A99"),
		OutdoorAmbient = Color3.fromHex("#8C9BB8"),
		EnvironmentDiffuseScale = 0.6,
		EnvironmentSpecularScale = 0.25,
		ExposureCompensation = 0.1,
		ColorCorrection = { Contrast = 0.08, Saturation = 0.12, Brightness = 0.02, TintColor = Color3.fromHex("#FFF6E8") },
		Bloom = { Intensity = 0.4, Size = 24, Threshold = 1.4 },
		SunRays = { Intensity = 0.04, Spread = 0.6 },
		Atmosphere = { Density = 0.28, Offset = 0.15, Color = Color3.fromHex("#C9DCF5"), Decay = Color3.fromHex("#8FA7CC"), Glare = 0.2, Haze = 1.1 },
		Clouds = { Cover = 0.55, Density = 0.6, Color = Color3.fromHex("#FFFFFF") },
	},
	-- Low graphics (quality 1-3): no Bloom / SunRays, lighter atmosphere
	LowQualityLevel = 3,
}
