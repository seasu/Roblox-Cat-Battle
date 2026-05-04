local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatData = require(ReplicatedStorage.Shared.CatData)
local EquipmentData = require(ReplicatedStorage.Shared.EquipmentData)
local DataStore = require(script.Parent.DataStore)

local ShopManager = {}

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local purchaseResultEvent = remoteEvents:WaitForChild("PurchaseResult")

-- productId -> catId 反向查找表
local productToCat: { [number]: string } = {}

function ShopManager.init()
	for catId, cat in pairs(CatData.cats) do
		if cat.productId then
			productToCat[cat.productId] = catId
		end
	end

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local catId = productToCat[receiptInfo.ProductId]
		if not catId then
			warn("[ShopManager] 未知的 ProductId：", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok, err = pcall(function()
			local data = DataStore.getData(player)
			if data then
				data.ownedCats[catId] = true
				DataStore.savePlayer(player)
			end
		end)

		if ok then
			local cat = CatData.getCatById(catId)
			local name = cat and cat.displayName or catId
			purchaseResultEvent:FireClient(player, true, "恭喜獲得「" .. name .. "」！")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("[ShopManager] ProcessReceipt 發生錯誤：", err)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
end

function ShopManager.handlePurchaseRequest(player: Player, catId: string)
	local cat = CatData.getCatById(catId)
	if not cat or not cat.productId then
		purchaseResultEvent:FireClient(player, false, "無效的貓咪 ID。")
		return
	end
	local data = DataStore.getData(player)
	if data and data.ownedCats[catId] then
		purchaseResultEvent:FireClient(player, false, "你已經擁有這隻貓咪了！")
		return
	end
	MarketplaceService:PromptProductPurchase(player, cat.productId)
end

function ShopManager.handleCoinPurchase(player: Player, itemId: string)
	local data = DataStore.getData(player)
	if not data then return end

	local item = EquipmentData.getItemById(itemId)
	if not item then
		purchaseResultEvent:FireClient(player, false, "無效的物品 ID。")
		return
	end

	if data.coins < item.price then
		purchaseResultEvent:FireClient(player, false, "金幣不足！需要 " .. item.price .. " 金幣。")
		return
	end

	data.coins -= item.price
	purchaseResultEvent:FireClient(player, true, "成功購買「" .. item.displayName .. "」！")

	local remotes = game.ReplicatedStorage:WaitForChild("RemoteEvents")
	remotes:WaitForChild("UpdateUI"):FireClient(player, "coins", -item.price)
end

-- 購買裝備（金幣）並同時裝備上去
function ShopManager.handleBuyEquipment(player: Player, itemId: string)
	local data = DataStore.getData(player)
	if not data then return end

	local item = EquipmentData.getItemById(itemId)
	if not item then
		purchaseResultEvent:FireClient(player, false, "無效的裝備 ID。")
		return
	end
	if data.coins < item.price then
		purchaseResultEvent:FireClient(player, false,
			"金幣不足！需要 " .. item.price .. " 金幣，目前只有 " .. data.coins .. " 金幣。")
		return
	end

	data.coins -= item.price
	data.equipment[item.slot] = itemId

	local remotes = game.ReplicatedStorage:WaitForChild("RemoteEvents")
	remotes:WaitForChild("EquipmentChanged"):FireClient(player, data.equipment)
	remotes:WaitForChild("UpdateUI"):FireClient(player, "coins", -item.price)
	purchaseResultEvent:FireClient(player, true, "已裝備「" .. item.displayName .. "」！")
end

function ShopManager.getCatalog()
	local cats = {}
	for catId, cat in pairs(CatData.cats) do
		if cat.price > 0 then
			table.insert(cats, {
				id = catId,
				displayName = cat.displayName,
				description = cat.description,
				price = cat.price,
				productId = cat.productId,
				innateSkills = cat.innateSkills,
			})
		end
	end
	table.sort(cats, function(a, b) return a.price < b.price end)
	return cats
end

return ShopManager
